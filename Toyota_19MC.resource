*** Settings ***
#=================================================================
# Standard Library
#=================================================================
Resource    ../../../dqa_common_rbf/resource/Telematics_Common.resource
Resource    Toyota_19MC_Data.resource
Library    random
Library     KeysightPower.py
Library    ExportExcelResult.py
Library    GetTestResult.py
Library    String
Library    robot.utils

#=================================================================
# Plugin
#=================================================================

*** Keywords ***
Test-Precondition
    [Documentation]    `Test-Precondition` step
    ...    - make IMG directory in `${workspace}`
    ...    - Connect CANat.
    ...    - Connect Bench
    ...    - Connect MCU/MDM uart.
    ...    - Turn on Battery, IGN key using Bench
    ...    - Turn on ACC ON/OFF by send CAN message
    ...    - Check ADB connection
    ...    - Set telematics flag ON
    ...    - Set Standby timer
    ...    - Check SIM, CALL state
    ...    - Clear all DTC, config airbag signal is normal
    ...    - Check Bench in Normal mode

    Log with time    - Create Log Path
    Precondition_CreateLogPath     ${MODEL}

    Log with time    ${SUITE NAME}
    Log with time    -- Test Precondition Start
    
    Log with time    -- Boot target
    Init CANat  			${CANAT_PORT}           ${CANAT_LOG_PATH}
    Log with time    -- CANat , log_path ${CANAT_LOG_PATH}

    Log With Time    - Bench Start, ${BENCH_TYPE}, ${COMMON_BENCH_PORT}
    Init Bench      ${BENCH_TYPE}
    Sleep    1
    
    ${result}=    Connect Bench
    IF    '${result}' == "CONNECTED"
        Log With Time    -- Bench Connect
    ELSE
        Run Keyword    Fail    Bench is not Connected!!!
    END

    Log with time    -- Connect waiting booting time
    Log With Time    - adb wait-for-device -
    Wait for ADB Device

    # OPEN UART PORT
    # IF  ${USE_UART_PORT} == 1
    #     AP.Add Uart Port              	${AP_PORT}                    	${AP_BPS}                	${AP_LOG_PATH}
    #     # MCU.Add Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}
    # ELSE
    #     AP.Add Uart Port              	${AP_PORT}                    	${AP_BPS}                	${AP_LOG_PATH}
    #     MCU.Add Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}
    #     Open MCU UART PORT
    #     Open MDM UART PORT
    # END

    Log with time    -- Battery ON
    BATTERY    ON
    Log with time    -- CAN Send
    CANAT.Start Save CAN Message
    Log with time    -- Connect IG ON Start
    Bench Turn The Ignition Key    ON
    Log with time    -- Turn ON ACC
    CANat Send ACC CAN msg    OFF
    CANat Send ACC CAN msg    ON

    Log with time    -- Connect waiting booting time
    Log With Time    - adb wait-for-device -
    Wait for ADB Device

    SLEEP  5

    Log With Time     Change Telematics value
    ${flag_check_tag}    Run Keyword And Return Status    Should Contain Any    ${TEST_TAGS}    ACN    SOS
    ${cmd_set_Telematics_value}     Set Variable If    ${flag_check_tag} == True        sldd cli setData Telematics U8 1    sldd cli setData Telematics U8 0

    Send and Find ADB String    ${cmd_set_Telematics_value}    2    Success to change data Telematics    ${ADB_SERIAL}

    Send ADB String   sync    ${ADB_SERIAL}

    Send ADB String   rm -rf /data/ramoops/*    ${ADB_SERIAL}

    Send ADB String   rm -rf /data/logger/*    ${ADB_SERIAL}
    Send ADB String   reboot -f    ${ADB_SERIAL}
    Log with time    - Sleep 180s until board reboot completed
    Log with Sleep    180
    Wait for ADB Device
    #Configure standby timer with operation mode is shipping mode(with operation mode is eCall mode only use command "sldd pmm setStandbyTime 1 120 120")
    ${flag_check_operation_mode}    Run Keyword And Return Status    Send and Find ADB String   cat /tmp/property    2    rw.0_prop_shipping=1    ${ADB_SERIAL}
    # #${flag_check_operation_mode} is True it's mean operation is eCall mode only.
    Run Keyword If    ${flag_check_operation_mode} == False    Send and Find ADB String    sldd pmm setStandbyTime 0 120 120    2    Success to update 0    ${ADB_SERIAL}

    Log with time                   -- Pre Condition Clear DTC
    Clear DTC
    DTC for BOB_MET
    Send All CAN Message Stop
    Airbag Crash Detection
    SLEEP  5

    Log with time                   -- Read Bench Current
    Wait Until Keyword Succeeds    6x    10s    Bench Check input current    Normal Mode
    Log with time                   -- Create Excel file to save data
    Create Excel File to Save Result    ${TEST_NAME}
    Sleep    3
    # ${end_line_AP}=    Get End Line        ${AP_LOG_PATH}
    # ${end_line_MCU}=    Get End Line        ${MCU_LOG_PATH}
    # Set Global Variable    ${end_line_AP}
    # Set Global Variable    ${end_line_MCU}
    Log with time                   -- Test Precondition End

Test-Postcondition
    [Documentation]    `Test-Postcondition` step
    ...    - Turn ON battery, IGN
    ...    - Check ADB device connection
    ...    - Stop send all CAN msg and Disconnect CANat
    ...    - Check Bench in normal mode then Disconnect Bench Connection
    ...    - Adb pull /data/logger and check tigris file
    ...    - Adb pull /data/coredump
    ...    - Disconnect ALL UART
    Log With Time    -- PostCondition is Started

    BATTERY    ON
    Bench Turn The Ignition Key    ON
    Sleep    10

    Log with time    -- Connect waiting booting time
    Log With Time    - adb wait-for-device -
    Wait for ADB Device
    Sleep    2
    #Check ADB port connect or not, if lost ADB port, reconnect ADB by control Bench
    ${flag_check_ADB_port}    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
    Run Keyword If    ${flag_check_ADB_port} == ${False}    Reconnect ADB Port by Control Bench

    Send All CAN Message Stop
    CANAT.Disconnect CANat
    Sleep    1

    # logger Log Pull
    Log With Time    - Logger Log pull
    Win CMD    adb -s ${ADB_SERIAL} pull /data/logger ${CRASH_PATH}
    Sleep    2

    # Coredump Pull
    Log With Time    - coredump pull
    Win CMD    adb -s ${ADB_SERIAL} pull /data/coredump ${CRASH_PATH}
    Sleep    2

    Log with time                   -- Read Bench Current
    # Wait Until Keyword Succeeds    6x    10s    Bench Check input current    Normal Mode
    Disconnect Bench

    Log With Time    - Check the Tigris
    ${tigris_cnt}=      Check Tigris File    ${CRASH_PATH}   ${ADB_SERIAL}
    IF   ${tigris_cnt} != 0
        Log With Time    - Tigris exist, adb pull coredump
#        Run And Return Rc And Output    adb -s ${ADB_SERIAL} pull /data/coredump/ ${CRASH_PATH}
        Run Keyword    Fail    Tigris file existse!!!
    END
    Log With Time    -- PostConditin is ended
    Log With Time    -- wait at least 5mins
#    Sleep    300

    # IF    ${USE_UART_PORT} == 1
    #     AP.Close Uart Port
    #     # MCU.Close Uart Port
    # ELSE
    #     AP.Close Uart Port
    #     MCU.Close Uart Port

    #     Sleep    2
    #     Log With Time    - Log files moves
    # END
    
    # Set Global Variable    ${end_line_AP}    ${0}
    # Set Global Variable    ${end_line_MCU}    ${0}

    Log With Time    - Post condition End

Test-Precondition-Keysight
    [Documentation]    `Test-Precondition` step
    ...    - make IMG directory in `${workspace}`
    ...    - Connect CANat.
    ...    - Connect Bench
    ...    - Connect MCU/MDM uart.
    ...    - Turn on Battery, IGN key using Bench
    ...    - Turn on ACC ON/OFF by send CAN message
    ...    - Check ADB connection
    ...    - Set telematics flag ON
    ...    - Set Standby timer
    ...    - Check SIM, CALL state
    ...    - Clear all DTC, config airbag signal is normal
    ...    - Check Bench in Normal mode

    Log with time    - Create Log Path
    Precondition Create Log Path     ${MODEL}

    Log with time    ${SUITE NAME}
    Log with time    -- Test Precondition Start
    
    Log with time    -- Boot target
    Init CANat  			${CANAT_PORT}           ${CANAT_LOG_PATH}
    Log with time    -- CANat , log_path ${CANAT_LOG_PATH}

    Log With Time    - Bench Start, ${BENCH_TYPE}, ${COMMON_BENCH_PORT}
    Init Bench      ${BENCH_TYPE}

    Sleep    1
    
    ${result}=    Connect Bench
    IF    '${result}' == "CONNECTED"
        Log With Time    -- Bench Connect
    ELSE
        Run Keyword    Fail    Bench is not Connected!!!
    END

    # OPEN UART PORT
    IF  ${USE_UART_PORT} == 1
        AP.Add Uart Port              	${AP_PORT}                    	${AP_BPS}                	${AP_LOG_PATH}
        MCU.Add Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}
    ELSE
        AP.Add Uart Port              	${AP_PORT}                    	${AP_BPS}                	${AP_LOG_PATH}
        MCU.Add Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}
        Open MCU UART PORT
        Open MDM UART PORT
    END
    #Start Save log in AP and MCU
    AP.Start Save File    ${AP_LOG_PATH}
    MCU.Start Save File    ${MCU_LOG_PATH}

    Log with time    -- Battery ON
    BATTERY    ON
    Log with time    -- CAN Send
    CANAT.Start Save CAN Message
    Log with time    -- Connect IG ON Start
    Bench Turn The Ignition Key    ON
    Log with time    -- Turn ON ACC
    CANat Send ACC CAN msg    OFF
    CANat Send ACC CAN msg    ON

    Log with time    -- Connect waiting booting time
    Log With Time    - adb wait-for-device -
    Wait for ADB Device

    SLEEP  5

    Log With Time     Success to change data Telematics

    #Config value = 0 , operation change to shipping mode, value = 1 change to eCall mode only
    Send and Find ADB String    sldd cli setData Telematics U8 0    2    Success to change data Telematics    ${ADB_SERIAL}

    # Configure standby timer with operation mode is shipping mode(with operation mode is eCall mode only use command "sldd pmm setStandbyTime 1 120 120")
    Send and Find ADB String    sldd pmm setStandbyTime 0 120 120    2    Success to update 0    ${ADB_SERIAL}

    Send ADB String   sync    ${ADB_SERIAL}
    Send ADB String   rm -rf /data/ramoops/*    ${ADB_SERIAL}
    Send ADB String   rm -rf /data/logger/*    ${ADB_SERIAL}
    Log with time                   -- Pre Condition Clear DTC
    Clear DTC
    DTC for BOB_MET
    # Airbag Crash Detection
    SLEEP  5
    Connect Keysight and set voltage    12
    Sleep    3
    Log with time                   -- Create Excel file to save data
    Create Excel File to Save Result    ${TEST_NAME}
    Log with time                   -- Test Precondition End

Test-Postcondition-Keysight
    [Documentation]    `Test-Postcondition` step
    ...    - Turn ON battery, IGN
    ...    - Check ADB device connection
    ...    - Stop send all CAN msg and Disconnect CANat
    ...    - Check Bench in normal mode then Disconnect Bench Connection
    ...    - Adb pull /data/logger and check tigris file
    ...    - Adb pull /data/coredump
    ...    - Disconnect ALL UART
    Log With Time    -- PostCondition is Started

    BATTERY    ON
    Bench Turn The Ignition Key    ON
    Sleep    10

    Log with time    -- Connect waiting booting time
    Log With Time    - adb wait-for-device -
    Wait for ADB Device
    Sleep    2

    Send All CAN Message Stop
    Sleep    5
    CANAT.Disconnect CANat
    Sleep    1

    # logger Log Pull
    Log With Time    - Logger Log pull
    Win CMD    adb -s ${ADB_SERIAL} pull /data/logger ${CRASH_PATH}
    Sleep    2

    # Coredump Pull
    Log With Time    - coredump pull
    Win CMD    adb -s ${ADB_SERIAL} pull /data/coredump ${CRASH_PATH}
    Sleep    2

    Connect Keysight and set voltage    12
    KeysightPower.Close Power Supply

    Disconnect Bench

    Log With Time    - Check the Tigris
    ${tigris_cnt}=      Check Tigris File    ${CRASH_PATH}   ${ADB_SERIAL}
    IF   ${tigris_cnt} != 0
        Log With Time    - Tigris exist, adb pull coredump
#        Run And Return Rc And Output    adb -s ${ADB_SERIAL} pull /data/coredump/ ${CRASH_PATH}
        Run Keyword    Fail    Tigris file existse!!!
    END
    Log With Time    -- PostConditin is ended
    Log With Time    -- wait at least 5mins
#    Sleep    300

    IF    ${USE_UART_PORT} == 1
        AP.Close Uart Port
        MCU.Close Uart Port
    ELSE
        AP.Close Uart Port
        MCU.Close Uart Port

        Sleep    2
        Log With Time    - Log files moves
    END

    Set Global Variable    ${end_line_AP}    ${0}
    Set Global Variable    ${end_line_MCU}    ${0}

    Log With Time    - Post condition End


#--------------ADB check -------------------
Wait for ADB Device
    [Documentation]    'wait for ADB Device' step
    ...             - start process adb and wait until adb device was connected
    ...             - If there is exist adb process but it is not running well, then terminate process and start again
    Log With Time    - adb wait-for-device -
    ${process_Adb}    Start Process    adb -s ${ADB_SERIAL} wait-for-device    shell=True
    Wait For Process    ${process_Adb}    timeout=120 secs
    ${flag_check}    Run Keyword And Return Status    Is Process Running    ${process_Adb}
    Run Keyword If    ${flag_check}==False    Terminate Process    ${process_Adb}    kill=true
    Run Keyword If    ${flag_check}==False    Run Process    adb -s ${ADB_SERIAL} wait-for-device    shell=True
    Run And Return Rc And Output    adb -s ${ADB_SERIAL} root
    # Run Process    adb -s ${ADB_SERIAL} wait-for-device    shell=True
    ADB.Connect Adb Server
    ADB.Select Device    ${ADB_SERIAL}
    Log with time    -- ADB connected

Check Devices in TYT
	[Arguments]    ${ADB_SERIAL}
    [Documentation]    `Check Devices in TYT` step
    ...                 '- Check device is displayed in list devices name'
    ...                 'Return error if devices is absent'
    Log With Time    -ADB connect server
    ${idx}    Set Variable     0
    ADB.Connect Adb Server
    ADB.Select Device    ${ADB_SERIAL}
    @{adb_list}=   Adb Devices
    ${listLen}=    Get Length    ${adb_list}
    Log With Time    len ${listLen}
    FOR    ${idx}   IN RANGE    ${listLen}
        Log     ${adb_list}[${idx}]
        ${findLine}=   Get Lines Containing String    ${adb_list}[${idx}]    ${ADB_SERIAL}
        IF    '${findLine}' != ''
            Log With Time    - ADB Device Check : ${findLine}
            BREAK
        END
    END
    IF    '${findLine}' == ''
            Run Keyword And Continue On Failure    Fail    ◆◆◆ ADB Device Check FAIL ◆◆◆
    END

#------------------BENCH (S)----------------------------

Bench Turn the ignition key
    [Documentation]    'Ignition Key` step
    ...    - Turn On/Off Ignitionion Key
    [Arguments]    ${status}
    IF  ${BENCH_TYPE} == 0
        # Common Bench
        IGN         ${status}
        USB1        ${status}
    ELSE IF  ${BENCH_TYPE} == 1
        # Smart Bench
        IGN         ${status}
        IGN3        ${status}
    ELSE
        IG2    ${status}
    END
    Log With Time    - Ignition Key ${status}!!! -
    Sleep    5

Bench Check input current
    [Arguments]    ${PM}
    [Documentation]    `Check input current` step
    ...    - Checking the current
    ...    - Current should be between
    ...    - 'Normal Mode' Current should be between 0.05 and 0.55
    ...    - 'Standby Mode' Current should be between 0.002 and 0.040
    ...    - 'Stop Mode' Current should be between 0.000 and 0.001
    ...    - 'Wake up Mode' Current should be between 0.025 and 0.400
    ...    - Return 'fail' or 'pass'
    Log With Time   - Check input current ${PM}
    
    IF    '${PM}' == 'Normal Mode'
        IF    ${USE_KIKUSUI} !=1
            ${result}    ${timeStamp}    ${current_list}=   Check Input Current Bench    min_current=0.05    max_current=0.55    check_delay=60000

        END
        IF    '${result}' == 'pass'
            Log With Time    - Current Check PASS. ${current_list} -
            Log With Time    - Entry Time is ${timeStamp} -
        ELSE
            Log With Time    - Currnet Check FAIL!!! ${current_list} -
            Log With Time    - Elapsed Time is ${timeStamp} -
            Log With Time   [Fail] ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
            Run Keyword And Continue On Failure    Fail    ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
        END
    ELSE IF    '${PM}' == 'Standby Mode'
        IF    ${USE_KIKUSUI} !=1
            ${result}    ${timeStamp}    ${current_list}=   Check Input Current Bench    min_current=0.002    max_current=0.040    check_delay=60000

        END

        IF    '${result}' == 'pass'
            Log With Time    - Current Check PASS. ${current_list} -
            Log With Time    - Entry Time is ${timeStamp} -
        ELSE
            Log With Time    - Currnet Check FAIL!!! ${current_list} -
            Log With Time    - Elapsed Time is ${timeStamp} -
            Check PowerLock State
            Log With Time    [Fail] ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
            Run Keyword And Continue On Failure    Fail    ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
        END
    ELSE IF    '${PM}' == 'Stop Mode'
        IF    ${USE_KIKUSUI} !=1
            ${result}    ${timeStamp}    ${current_list}=   Check Input Current Bench    min_current=0.000    max_current=0.001   check_delay=60000

        END

        IF    '${result}' == 'pass'
            Log With Time    - Current Check PASS. ${current_list} -
            Log With Time    - Entry Time is ${timeStamp} -
        ELSE
            Log With Time    - Currnet Check FAIL!!! ${current_list} -
            Log With Time    - Elapsed Time is ${timeStamp} -
            Log With Time    [Fail] ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
            Run Keyword And Continue On Failure    Fail    ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
        END
    ELSE IF    '${PM}' == 'Wake up Mode'
        IF    ${USE_KIKUSUI} !=1
            ${result}    ${timeStamp}    ${current_list}=   Check Input Current Bench    min_current=0.025    max_current=0.400    check_delay=60000

        END

        IF    '${result}' == 'pass'
            Log With Time    - Current Check PASS. ${current_list} -
            Log With Time    - Entry Time is ${timeStamp} -
        ELSE
            Log With Time    - Currnet Check FAIL!!! ${current_list} -
            Log With Time    - Elapsed Time is ${timeStamp} -
            Log With Time    [Fail] ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
            Run Keyword And Continue On Failure    Fail    ◆◆◆ ${pm} Current is not expected value!!! ◆◆◆
        END
    END

Airbag Crash Detection
    [Documentation]     'Airbag Crash Detection'
    ...             - Model: Toyota
    ...             - Status: Normal, Crash, Abnormal, NoSignal
    ...             - Input bench type and status of airbag signal.
    ...             - Common bench type is 0, status Normal is 0
    Airbag Pattern    0    0


Reconnect ADB Port by Control Bench
    [Documentation]     'Reset ADB port' step
    ...                - Turn OFF Battery, IGN, USBV and then turn ON to make ADB port connect again
    Log With Time    - Reconnect ADB Port by Control Bench
    BATTERY    OFF
    Bench Turn The Ignition Key    OFF
    Sleep    5
    BATTERY    ON
    Bench Turn The Ignition Key    ON
    Log With Time    - Sleep 60s to wait ADB port reconnect
    Sleep    60

#----------- CANat (S) -----------------------------------------
CANat Send ACC CAN msg
    [Documentation]    ACC CAN Msg Send / PDC1G01
    ...    - Control ACC ON/OFF by send CAN Msg
    [Arguments]    ${status}
    Log With Time    - Send ACC CAN msg
    IF  '${status}' == 'ON' or '${status}' == 'on'
        CANAT.Send CAN Message    message_id=0x2d1    cycle_time=300    can_message=00 00 01 00 00 00 00 00    bus_channel=1
        Sleep   1
    ELSE
        CANAT.Send CAN Message    message_id=0x2d1    cycle_time=300    can_message=00 00 00 00 00 00 00 00    bus_channel=1
        Sleep   1
    END

CANat Send Wakeup Signal CAN msg
    [Documentation]    `Wakeup signal` step / ENG1S51
    ...                - Send CAN Msg to make target board wake up.
    CANAT.Send CAN Message    message_id=0x45A    cycle_time=1500    can_message=00 00 00 00 00 00 00 00    bus_channel=1
    Sleep    1

CANat Send Signal CAN msg list
    [Documentation]    Send many CAN Msg with data input.
    ...             - Input many CAN msg and then perform send sequently
    ...             - Data input define in the Data.resource file
    ...             - Return None
    [Arguments]    ${data}
    ${list_data}    Split String    ${data}    ","
    ${number_send}    Get Length    ${list_data}
    Log    ${list_data}
    FOR    ${i}    IN RANGE    0    ${number_send}
        ${msg_sequence}    Set Variable    ${list_data}[${i}]
        ${msg}    Split String    ${msg_sequence}    ,
        ${msg_id}    Set Variable    ${msg}[0]
        Log    ${msg_id}
        ${data}    Set Variable    ${msg}[3]
        Log   'Send CAN message ${msg_id}'
        CANAT.Send CAN Message    message_id=${msg_id}    cycle_time=300    can_message=${data}    bus_channel=1
    END

DTC for BOB_MET
    [Documentation]
    ...    - Clear DTC for BOB and MET via CAN message
    ...    - Return None
    Log With Time    - DTC for BOB_MET
    # DTC for BDB
    CANAT.Send CAN Message    message_id=0x638   cycle_time=1000    can_message=00 00 00 00 00 00 00 00    bus_channel=1
    Sleep    1
    # DTC for MET
    CANAT.Send CAN Message    message_id=0x611    cycle_time=1000    can_message=00 00 00 00 00 00 00 00   bus_channel=1

Clear DTC
    [Documentation]    'Clear DTC` step
    ...    - Clear DTC Command , no argument
    ...    - Clear DTC via CAN message
    ...    - Return None
    Log With Time    - Clear DTC
    CANAT.Send CAN Message    message_id=0x750   cycle_time=1000    can_message=C7 04 14 FF FF FF 00 00    bus_channel=1

    # DCM should response CAN ID : 758 (physical) 01 54


Check rmnet data
    [Documentation]    `Check Data Connection` step
    ...    - Check Data Connection (when insert SIM data should be rmnet_data0)
    ...    - ifconfig
    ...    - device : ADB, AP ...
	[Arguments]    ${device}
    Log With Time    - Check Data connection
    FOR    ${i}    IN RANGE    5
        ${result}=    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
        IF    ${result} == True    BREAK
        Sleep    10s
    END

    IF    ${result} == True
        IF    '${device}' == 'ADB'
            Run Keyword And Continue On Failure    Send and Find ADB String    ifconfig    2    rmnet0    ${ADB_SERIAL}
        ELSE IF    '${device}' == 'AP'
            Run Keyword And Continue On Failure    Send and Find UART String    ifconfig    2    rmnet0    ${AP_LOG_PATH}
        END
    ELSE
        Run Keyword And Continue On Failure    Fail    ADB Device Check FAIL
    END
#-------------------------- Serial (UART) (S) -----------------------------------------

Check PowerLock State
    [Documentation]    'Check PowerLock State`
    ...    - Leave the log to the UART to check power lock status
    Log With Time    - Check PowerLock State
    Send UART String    sldd power state


Open MCU UART PORT
    [Documentation]    `Open MCU UART PORT` step
    ...    - Open MCU UART
    ${set_cmd}    Set Variable     "C://Program Files (x86)//teraterm//ttermpro.exe" /C=6 /BAUD=115200
    Win Sub CMD    ${set_cmd}

Open MDM UART PORT
    [Documentation]    `Open MDM UART PORT` step
    ...    - Open MDM UART
    ${set_cmd}    Set Variable     "C://Program Files (x86)//teraterm//ttermpro.exe" /C=5 /BAUD=115200
    Win Sub CMD    ${set_cmd}

Wait for DCM Booting Time
    [Documentation]    `Wait for DCM Booting Time` step
    ...    - Wait for DCM Booting time
    ...    - Devices Check
    [Arguments]    ${time_delay}=120
    Log With Time    - Wait for DCM Booting Time -
    Sleep    ${time_delay}

    FOR    ${i}    IN RANGE    5
        ${result}=    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
        IF    ${result} == True    BREAK
        Sleep    10s
    END
    
    IF    ${result} != True
        Bench Turn the ignition key    OFF
        Sleep    1
        Bench Turn the ignition key    ON
        Sleep    5
        Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    3x    10s    Check Devices in TYT    ${ADB_SERIAL}
    END
    Run Keyword And Continue On Failure    Check Devices in TYT    ${ADB_SERIAL}

Reconnect MCU when check fail
    [Documentation]    Disconnect MCU port and reconnect again
    ...             - Close MCU Uart port and reopen when occur error with save log in path.
    MCU.Close Uart Port
    Sleep    5
     # OPEN UART PORT
    MCU.Connect Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}
    Sleep    5
    
Make DCM SW Reset
    [Documentation]    'Make DCM SW Reset' step
    # DCM SW reset
    Bench Turn the ignition key    OFF
    CANat Send ACC CAN msg    OFF
    BATTERY    OFF
    Sleep    5
    BATTERY    ON
    CANat Send ACC CAN msg    ON
    Bench Turn the ignition key    ON

# ------------------------------MCU-----------------------

Send command in DIAG port
    [Documentation]    Send command in Diagnostics port
    ...    - Send command to perform
    [Arguments]    ${uart_command}
    # OPEN UART PORT
    MCU.Connect Uart Port              	${DIAG_PORT}                    	${DIAG_BPS}
    Sleep    5
    # send String(Command)
    Log With Time    - send command in Diagnostics port: ${uart_command}
    Log    ${uart_command}
    MCU.Send String To Uart    ${uart_command}
    MCU.Send String To Uart    \r
    Sleep    1
    MCU.Send String To Uart    \n
    MCU.Close Uart Port
    MCU.Connect Uart Port              	${MCU_PORT}                    	${MCU_BPS}                	${MCU_LOG_PATH}



Send Command And Get BUB Log In MCU 
    [Documentation]    Send command and get BUB log 
    [Arguments]    ${uart_command}    @{find_string}    ${reverse}=False    ${find_from_0}=False
    Log With Time    - Send and Find UART MCU String
    ${sfend_line}=    Set Variable    ${end_line_MCU}
    Sleep    1
    IF    ${find_from_0}
        ${sfend_line}=    Set Variable    ${0}
    END
    Log    - Start line: ${sfend_line}    console=yes
    #AP UART Login    root    oelinux123
    # send String(Command)
    Log With Time    - send command : ${uart_command}
    Log    ${uart_command}
    MCU.Send String To Uart    ${uart_command}
    MCU.Send String To Uart    \r
    Sleep    1
    MCU.Send String To Uart    \n
    Sleep    3 
    ${joined_find_string}=    Catenate    SEPARATOR=    @{find_string}
    Log With Time    - find string : ${find_string}
    ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${MCU_LOG_PATH}     findString=${joined_find_string}   start_line=${sfend_line}
    Sleep    1
    Log With Time    - find ${INDEX}, ${return_str}
    ${ret_len}=     Get Length    ${return_str}
    Sleep    1
    IF    ${ret_len} != 0
        ${found}=    Set Variable    True
        Log With Time    - find UART MCU Log : ${find_string} [PASS]
        RETURN    ${return_str}
    ELSE
        Log With Time    Fail find UART MCU Log : ${find_string} [FAIL]
    END
    ${sfend_line}=    Get End Line        ${MCU_LOG_PATH}
    Log With Time    - endLine : ${sfend_line}

Check BUB voltage value
    [Documentation]    Check BUB voltage in range 3800-4100 mV
    ...             - Send command "bub" and Check log in MCU
    ...             - Key word success when BUB voltage in range 3800-4100 mV
    ...             - min_BUB_value = 3800, max_BUB_value = 4100, define in X_Data.resource
    # ${MCU_LOG_PATH}    Send command and get log in MCU    bub
    ${log}    Send Command And Get BUB Log In MCU    bub    BUB voltage
    Sleep    1
    ${result}    Get Regexp Matches    ${log}    \\d+\\.\\d+mV
    ${length}    Get Length    ${result}
    IF   ${length} != 0
        ${result}    Replace String    ${result[0]}    mV    ${EMPTY}
        ${num_check}    Convert To Number    ${result}
        Log With Time    ◆◆◆ BUB Voltage: ${num_check}mV ◆◆◆ 
        Should Be True    ${min_BUB_value} * 100 <= ${num_check} <= ${max_BUB_value} * 100    BUB voltage: ${num_check}mV is out of range
    ELSE
        Run Keyword And Continue On Failure    Fail     BUB Voltage check FAIL
    END

Find MCU String
    [Documentation]    'Find UART String`
    ...    - Send UART commands and Compare the Log Keyword
    ...    - uart_command : UART Command(Send String)
    ...    - start_line : Line to start find Compare the Log
    ...    - find_string : Compare the UART Log Keyword
    ...    - [RETURN] : Return the line that starts the next log Compare
	[Arguments]    ${find_string}    ${MCU_LOG_PATH}    ${fend_line}
    Log With Time    - Find MCU String

    # find String
    Log With Time    - find string Start line : ${fend_line}
    ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${MCU_LOG_PATH}     findString=${find_string}   start_line=${fend_line}
    Sleep    1
    Log With Time    - find ${INDEX}, ${return_str}
    ${ret_len}=     Get Length    ${return_str}
    Sleep    1
    IF    ${ret_len} != 0
        Log With Time    - find UART MCU Log : ${find_string} [PASS]
    ELSE
        Log With Time    Fail find UART MCU Log : ${find_string} [FAIL]
        Run Keyword And Continue On Failure    Fail    find UART MCU Log : ${find_string} [FAIL]
    END

    ${fend_line}=    Get End Line        ${MCU_LOG_PATH}
    Log With Time    - fend_line : ${fend_line}
    Sleep    1
    Return From Keyword    ${fend_line}

Send MCU String
    [Documentation]    'Send UART String`
    ...    - Send UART commands
    ...    - uart_command : UART Command(Send String)
	[Arguments]    ${uart_command}
    Log With Time    - Send UART String
    Sleep    1
    # send String(Command)
    Log With Time    - send command : ${uart_command}
    MCU.Send String To Uart        ${uart_command}
    Sleep    1
    MCU.Send String To Uart    exit
    Sleep    1

Send and Find MCU String
    [Documentation]    'Send and Find UART String`
    ...    - Send UART commands and Compare the Log Keyword
    ...    - uart_command : UART Command(Send String)
    ...    - delay : wait time after send UART command
    ...    - find_string : Compare the UART Log Keyword
	[Arguments]    ${uart_command}    ${delay}    ${find_string}
    
    ${bootType_0}    Set Variable    ${find_string}[0]
    ${mcu_bootup}    Set Variable    ${find_string}[1]
    ${bootType_1}    Set Variable    ${find_string}[2]

    Log With Time    - Send and Find UART MCU String
    #AP UART Login    root    oelinux123
    ${sfend_line}=    Get End Line        ${MCU_LOG_PATH}
    Sleep    1
    Log With Time    - endLine : ${sfend_line}
    Sleep    1
    # send String(Command)
    Log With Time    - send command : ${uart_command}
    Log    ${uart_command}
    MCU.Send String To Uart    ${uart_command}
    Sleep   ${delay}
    MCU. Send String to Uart   exit
    Sleep    1
    Log With Time    - find string : ${mcu_bootup}
    FOR    ${i}    IN RANGE    1200
        Log With Time    - Check log in MCU
        ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${MCU_LOG_PATH}     findString=${mcu_bootup}   start_line=${sfend_line}
        Sleep    1
        ${ret_len}=     Get Length    ${return_str}
        IF    ${ret_len} != 0
            ${INDEX_bootType_1}   ${return_bootType_1}=  LogCompare.Find String In Log File And Return Output     logFilePath=${MCU_LOG_PATH}     findString=${bootType_1}   start_line=${sfend_line}
            ${ret_len_1}=     Get Length    ${return_bootType_1}
        ELSE
            Continue For Loop
        END
        Exit For Loop If    ${ret_len_1} != 0
    END

    Log With Time    - find ${INDEX_bootType_1}, ${return_bootType_1}
    # ${ret_len}=     Get Length    ${return_str}
    # Sleep    1
    IF    ${ret_len_1} != 0
        Log With Time    - find UART MCU Log : ${bootType_1} [PASS]
    ELSE
        Log With Time    Fail find UART MCU Log : ${bootType_1} [FAIL]
        Run Keyword And Continue On Failure    Fail    find UART MCU Log : ${bootType_1} [FAIL]
    END

MCU Platform reset
    [Documentation]    'MCU Reset' Step
    ...             - Send command to reset MCU
    ...             - With board version V1 use command "reset", with version 2 use "mreboot"
    ...             - Key word run success when found log expected
    Log With Time    - MCU Platform Reset(Reset)
    ${command}    Set Variable If    ${verion_DCM}==2    mreboot    reset
    ${log_check}    Create List    Boot type 0    MCU BOOT-UP!!!!    Boot type 1 Request Platform Reset
    ${flag_check}   Run Keyword And Return Status    Send and Find MCU String    ${command}    30    ${log_check}
    Run Keyword If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Cannot found ${log_check}[2] in MCU log

Check DCM Power State changes
    [Documentation]    'Check Power Mode of Telematics`
    ...    - NORMAL
    ...    - STANDBY
    ...    - INIT
    ...    - STOP
	[Arguments]    ${power_state}
    Log With Time    - Check power state change to ${power_state}
    AP.Send String to Uart     \r
    MCU.Send String to Uart     \r
    Sleep    1
    AP.Send String to Uart     root
    Sleep    1
    AP.Send String to Uart     oelinux123
    Sleep    1
    AP.Send String to Uart     \r

    # ${end_line_AP}=    Get End Line        ${AP_LOG_PATH}
    # ${end_line_MCU}=    Get End Line        ${MCU_LOG_PATH}
    Log    - endLine AP ${end_line_AP}    console=yes
    Log    - endLine MCU ${end_line_MCU}    console=yes

    ${power_state}    Evaluate    '${power_state}'.title()
    
    IF    '${power_state}' == 'Stop'
        ${log_check_AP}    Set Variable    ${power_state}:transition yes
    ELSE
        ${log_check_AP_normal}    Create List    ${power_state}:transition yes    To${power_state}:trans
    END

    ${log_check_MCU}    Set Variable    CANBus
    ${INDEX_MCU}    Set Variable    ${end_line_MCU}
    ${status_MCU}    Set Variable    False
    
    IF    '${power_state}'=='Stop'
        ${status_MCU}    Set Variable    True
    ELSE
        FOR    ${i}    IN RANGE    3
            ${INDEX_MCU}   ${return_str_MCU}=  LogCompare.Find String In Log File And Return Output     logFilePath=${MCU_LOG_PATH}     findString=${log_check_MCU}    start_line=${INDEX_MCU}
            # Example log: 2025-01-17 10:23:04.841263 01:06:22:23:06:420 [CAN] CANBus(0) RepOK
            Log With Time    - line ${INDEX_MCU}: ${return_str_MCU}
            ${length_MCU}    Get Length    ${return_str_MCU}
            IF   ${length_MCU} != 0
                ${result_MCU}    Replace String    ${return_str_MCU}    (    ${SPACE}    # Replace ( with Space
                ${result_MCU}    Replace String    ${result_MCU}    )    ${SPACE}        # Replace ) with Space
                ${result_MCU}=    Split String    ${result_MCU}    ${SPACE}              # Split by Space
                ${result_MCU}=    Set Variable   ${result_MCU}[5] 
                IF    '${power_state}'=='Normal'
                    ${status_MCU} =    Run Keyword And Return Status    Should Be True    '${result_MCU}' == '2'
                ELSE IF    '${power_state}'=='Standby'
                    ${status_MCU} =    Run Keyword And Return Status    Should Be True    '${result_MCU}' == '0'
                ELSE    
                    BREAK
                END
                IF    '${status_MCU}'=='True'
                    BREAK
                END
            END
            ${INDEX_MCU} =    Evaluate    ${INDEX_MCU} + 1
        END
    END

    #Check log change power mode in AP port
    FOR    ${i}    IN RANGE    3
        # Example log: 2025-01-17 09:05:09.330067 [PowerModeState]: actNormalToStandby:transition yes
        IF    '${power_state}' == 'Stop'
            ${INDEX_AP}   ${return_str_AP}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check_AP}    start_line=${end_line_AP}
        ELSE
            TRY
                ${INDEX_AP}   ${return_str_AP}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check_AP_normal}[0]    start_line=${end_line_AP}
                ${length_AP}    Get Length    ${return_str_AP}
                Should Be True    ${length_AP} != 0
            EXCEPT    
                ${INDEX_AP}   ${return_str_AP}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check_AP_normal}[1]    start_line=${end_line_AP}
            END
        END

        Log With Time    - line ${INDEX_AP}: ${return_str_AP}
        ${length_AP}    Get Length    ${return_str_AP}
        ${status_AP} =    Run Keyword And Return Status    Should Be True    ${length_AP} != 0
        Exit For Loop If    '${status_AP}' == 'True'
        Sleep    1
    END

    IF    '${status_MCU}'!='True'
        Log With Time    ${power_state} MCU log check FAIL
        Run Keyword And Continue On Failure    Fail    MCU log check ${power_state} mode FAIL
    END
    IF    '${status_AP}'!='True'
        Log With Time    ${power_state} AP log check FAIL
        Run Keyword And Continue On Failure    Fail    AP log check ${power_state} mode FAIL
    END

    ${new_end_line_AP}=    Get End Line        ${AP_LOG_PATH}
    ${new_end_line_MCU}=    Get End Line        ${MCU_LOG_PATH}
    Set Global Variable    ${end_line_AP}    ${new_end_line_AP}
    Set Global Variable    ${end_line_MCU}    ${new_end_line_MCU}
    Log With Time    - endLine AP ${end_line_AP}
    Log With Time    - endLine MCU ${end_line_MCU}

MDM Reboot
    [Documentation]    'Check MDM Reboot Completed' step
    Log With Time    - Check USB connection
    ${end_line}=    Get End Line        ${AP_LOG_PATH}
    Log With Time    - endLine ${end_line}
    AP.Send String to Uart     \r
    Sleep    1
    AP.Send String to Uart     root
    Sleep    1
    AP.Send String to Uart     \r
    Sleep    1
    # AP.Send String to Uart     reboot: Restarting system
    # Sleep    1
    # AP.Send String to Uart     \r
    Sleep    1
    ${log_check}    Set Variable    reboot: Restarting system
    Log With Time    - Find log reboot completed in AP log
    ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check}    start_line=${end_line_AP}
    ${length}    Get Length    ${return_str}
    Should Be True    ${length} > 0    Check MDM Reboot Completed Success
    Log With Time    - find ${INDEX}, ${return_str}


Wait until DCM reset is done
    [Documentation]    'Wait until DCM reset is done' Step
    ...             - After found log bootComplete, check power state of DCM is normal
    [Arguments]    ${wait_timer}=150
    Log With Time    - Wait until DCM reset is done
    ${find_line}=    Get End Line        ${AP_LOG_PATH}
    Sleep    ${wait_timer}
    Run Keyword And Continue On Failure    Find UART String    bootComplete    ${AP_LOG_PATH}    ${find_line}
    Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    30x    10s   Check DCM Power State changes    NORMAL

Check GPS fixed
    [Documentation]    'Check GPS was fixed'
    ...             - Perform check GPSFixState in 360 times
    ...             - Send command and get state of GPS
    Log With Time    - Check GPS was fixed
    Wait for ADB Device
    FOR    ${i}    IN RANGE    0    360
        Log    ${i}

        ${flag_check_ADB}    Run Keyword And Return Status    Check Devices in TYT   ${ADB_SERIAL}

        Run Keyword If    ${flag_check_ADB}==False    Wait for ADB Device

        ${flag_check_GPS}    Run Keyword And Return Status    Send and Find ADB String    sldd loc getGPSFixState    5    GPS fixed     ${ADB_SERIAL}

        Exit For Loop If    ${flag_check_GPS}==True

        ${i}    Evaluate    ${i}+1
    END

    Should Be True    ${flag_check_GPS}    Check GPS was fixed success

    Check Devices in TYT    ${ADB_SERIAL}

Update FOTA version
    [Documentation]    'Update FOTA version UP/DOWN'
    ...             - push FOTA file in the folder /data/fota by command and check result
    ...             - Check FOTA file exist in folder by using command "ls"
    ...             - Send "sync" command and then send FOTA SW binary flashing command
    ...             - Send "cat /tmp/property" command and check result display include up/down version
    [Arguments]    ${link_folder_FOTA}    ${target_version_FOTA_check}
    Log With Time    - Update FOTA version UP/DOWN
    # UP/DOWN Package
    ${result}    Run    adb -s ${ADB_SERIAL} push ${link_folder_FOTA} /data/fota/

    Should Contain    ${result}    1 file pushed
    Sleep    1

    Send and Find ADB String     ls /data/fota/    10    FOTA_PKG.bin   ${ADB_SERIAL}

    Sleep    10

    #sync
    Send ADB String    sync    ${ADB_SERIAL}

    Sleep    10

    Send and Find ADB String    sldd fota sendMessageAsServer 20    10    sent   ${ADB_SERIAL}

    Send and Find ADB String    sldd fota sendMessageAsServer 21    10    sent    ${ADB_SERIAL}

    Send and Find ADB String    sldd fota sendMessageASClient 3    10    sent    ${ADB_SERIAL}

    Sleep    120

    #ADB offline check
    FOR   ${i}     IN RANGE   0    30
        Sleep    10
        ${flag_check}    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
        Exit For Loop If    ${flag_check} == False

    END

    Wait Until Keyword Succeeds    6x    10    Check Devices in TYT    ${ADB_SERIAL}

    #UP/DOWN version check
    Send and Find ADB String    cat /tmp/property    10    ${target_version_FOTA_check}    ${ADB_SERIAL}

    #Packget Del
    Send ADB String    rm /data/fota/pkg.up    ${ADB_SERIAL}

    Sleep    60

NAD reset
    [Documentation]    'NAD reset' step
    ${flag_check}    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
    Run Keyword If     ${flag_check} == False    Run Keyword And Continue On Failure    Fail    Check ADB device was failed
    Run Keyword If     ${flag_check} == True   Send ADB String    echo 0 > /sys/module/msm_poweroff/parameters/download_mode    ${ADB_SERIAL}

Wait NAD reset is done
    [Documentation]    'Wait NAD reset is done' step
    ${flag_check}    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}
    Run Keyword If     ${flag_check} == False   Run Keyword And Continue On Failure    Fail    Check ADB device was failed
    Run Keyword If     ${flag_check} == True    Send ADB String    echo c > proc/sysrq-trigger    ${ADB_SERIAL}
    Sleep    120

Check simState
    [Documentation]    'Check simState'
    ...             - Send sldd command and check state is ready
    [Arguments]    ${state_check}
    ${flag_check}    Run Keyword And Return Status    Send and Find ADB String    sldd telephony getSimstate    10     ${state_check}    ${ADB_SERIAL}
    Run Keyword If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Check simState ${state_check} Fail


Check callState
    [Documentation]    'Check callState'
    ...             - Send sldd command and check state is active
    [Arguments]    ${state_check}
    ${flag_check}    Run Keyword And Return Status   Send and Find ADB String    sldd telephony getCallstate    10     ${state_check}    ${ADB_SERIAL}
    Run Keyword If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Check callState ${state_check} fail

Check Current Mode of Bench
    [Documentation]    'perform action below when check current mode of bench fail'
    ...             - maximum timer for state change from stop to normal/ standby to normal is 35s
    ...             - perform check 4 loops with delay 10s in each loop
    [Arguments]    ${current_mode_check}
    Log With Time    - Check current mode of Bench
    FOR    ${i}    IN RANGE    1    8
        ${flag_check}    Run Keyword And Return Status    Bench Check input current    ${current_mode_check}
        Sleep    5
        Exit For Loop If    ${flag_check}==True
    END
    Run Keyword If     ${flag_check} == False   Run Keyword And Continue On Failure    Fail    Check Mode ${current_mode_check} of Bench failed

Check List
    [Documentation]    `Check List` step
    Log With Time    - Check List -
    Wait Until Keyword Succeeds    3x    10s    Check Devices in TYT    ${ADB_SERIAL}
    SLEEP  1
    # Send MCU String    Reset Factor
    SLEEP  5
    Check rmnet data    ADB

Press Emergency Call Button Short
    [Documentation]    'Press Emergency Call Button Short`
    ...    - Press Time : 2sec
    Log With Time   - Press Emergency Call Button Short
    Button Press    0    2
    Sleep    3

Disconnect Emergency call
    [Documentation]    'Emergency Call Cancel`
    ...     - Hang up Emergency Call
    Log With Time   - Emergency Call Cancel
    Sleep    5
    HangUp Call    ${PHONE_SN}
    Sleep    2
    Run Keyword And Continue On Failure    Check Testphone Call State    INACTIVATED

Check USB connection
    [Documentation]    `Check USB connection`
    ...    - Check USB is connected/disconnected using MDM log
    ...    - If connected -> argument is "diag: USB channel diag connected"
	[Arguments]    ${usb_state}
    Log With Time    - Check USB connection
    AP.Send String to Uart     \r
    Sleep    1
    AP.Send String to Uart     root
    Sleep    1
    AP.Send String to Uart     \r
    Sleep    1
    ${end_line}=    Get End Line        ${AP_LOG_PATH}
    Sleep    5
    Log With Time    - endLine ${end_line}
    ${log_check}    Set Variable    ${usb_state}
    ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check}
    ${length}    Get Length    ${return_str}
    Should Be True    ${length} > 0    Check USB is connected
    Log With Time    - find ${INDEX}, ${return_str}

CAN Bus Status on AP
    [Documentation]    `Check CAN Bus Release on AP`
    ...    - Check CAN Bus is woke up/released using MDM log
	[Arguments]    ${str_command}    ${can_bus_state}
    Log With Time    - Check CAN Bus Release on AP
    AP.Send String to Uart     \r
    Sleep    1
    AP.Send String to Uart     root
    Sleep    1
    AP.Send String to Uart     \r
    Sleep    1
    AP.Send String to Uart     ${str_command}
    AP.Send String to Uart     \r
    AP.Send String to Uart     \n
    Sleep    5
    ${end_line}=    Get End Line        ${AP_LOG_PATH}
    Sleep    1
    Log With Time    - endLine ${end_line}
    ${log_check}    Set Variable    ${can_bus_state}
    ${INDEX}   ${return_str}=  LogCompare.Find String In Log File And Return Output     logFilePath=${AP_LOG_PATH}     findString=${log_check}
    ${length}    Get Length    ${return_str}
    Should Be True    ${length} > 0    Check CAN Bus is woke up
    Log With Time    - find ${INDEX}, ${return_str}

#=================================================================
# Keysight Keyword
#=================================================================

Check Keysight Voltage
    [Arguments]    ${value}
    [Documentation]    `Check Keysight Voltage` steps
    ${current_status}    KeysightPower.Get Current Status
    ${voltage}    Get From List    ${current_status}    0
    ${diff}    Evaluate    abs(${voltage} - ${value})
    Should Be True    ${diff} < 0.01    Voltage is not ${value}V


Connect Keysight and set voltage
    [Arguments]    ${value}
    [Documentation]    `Connect Keysight and control voltage` steps
    Log With Time    - Connect Keysight
    # KeysightPower.Connect Power Supply    eth=169.254.245.47
    ${flag_check}    Run Keyword And Return Status    KeysightPower.Connect Power Supply
    Run Keyword And Return If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Connect Keysight was failed
    ${value}    Convert To Number    ${value}
    ${flag_check}    Run Keyword And Return Status    KeysightPower.Set Voltage    ${value}
    Run Keyword And Return If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Cannot configure voltage ${value}V for Keysight
    Check Keysight Voltage    ${value}

Send Worst Crank Pulse
    [Documentation]    `Send Worst Crank Pulse` steps
    Log With Time    - Send Worst Crank Pulse
    # KeysightPower.Connect Power Supply    eth=169.254.245.47
    KeysightPower.Connect Power Supply
    Connect Keysight and set voltage   11.4 
    Connect Keysight and set voltage    7.6
    Sleep    1.5
    Connect Keysight and set voltage    11.4

#=================================================================
# ECall Keyword
#=================================================================

Configure network and reset ADB device
    [Documentation]    Configure network and reset ADB device
    Send and Find ADB String   sldd telephony setradiopower off    2    off    ${ADB_SERIAL}
    Send and Find ADB String   sldd telephony setradiopower on    2    on    ${ADB_SERIAL}
    Send ADB String    reboot -f    ${ADB_SERIAL}
    Log with Sleep    180
    ${flag_check}    Run Keyword And Return Status    Wait for ADB Device
    Run Keyword And Return If    ${flag_check}==False    Run Keyword And Continue On Failure    Fail    Cannot check ADB device after reboot

Change to eCall Mode in Normal Mode
    [Documentation]    'Send ADB String to change Shipping Mode to Ecall Mode Only`
    Send and Find ADB String    sldd telephony setProperty tcu.carrier.swap.non.stc 1    2    set Property(1)    ${ADB_SERIAL}
    Send and Find ADB String    sldd sms testMtSmsMsg 07912801929162010405910510f90004320152718472632F534163735F61700a000a001300010a0000006373636E4646464646464646464646460010000000000a4353434E0d0a    2    result : SUCCESS    ${ADB_SERIAL}
    #Change to normal mode
    Run Keyword And Continue On Failure    Send and Find ADB String    sldd telephony eCallSetOperationMode 0    2    Result : 1    ${ADB_SERIAL}

Test case set up for eCall
    [Documentation]    `Test case set up for eCall` steps
    Log With Time    - Test case set up for eCall
    Send ADB String     sldd am setprop eCall CALL_AUTO_ANSWER_TIME_T9 60   ${ADB_SERIAL}
    Sleep    1
    Change to eCall Mode in Normal Mode
    # Set up phone number for testing
    Setup phone number for test    ${phone_number}
    Sleep    1
    #Configure standby timer with operation mode is ecall mode only
    # Send and Find ADB String   sldd pmm setStandbyTime 1 120 120    2    Success to update 1    ${ADB_SERIAL}
    Check SIM Service

Check SIM Service
    [Documentation]    `Check SIM Service` steps
    Log With Time    - Check SIM Service
    ${voice}=    Set Variable    (Voice) : 0 (IN SERVICE)
    ${data}=    Set Variable     (Data) \ : 0 (IN SERVICE)


    ${status_check_LTE}    Run Keyword And Return Status    Send and Find ADB String   sldd telephony getDataNetType    2    LTE    ${ADB_SERIAL}
    Run Keyword If    ${status_check_LTE}==False     Configure network and reset ADB device

    Send and Find ADB String   sldd telephony getDataNetType    2    LTE    ${ADB_SERIAL}
    Send and Find ADB String   sldd telephony getServiceState    2    ${voice}    ${ADB_SERIAL}
    Send and Find ADB String   sldd telephony getServiceState    2    ${data}    ${ADB_SERIAL}

Check Testphone Call State
	[Arguments]    ${State}
    [Documentation]    `Check Testphone Call State` step
    ...    - Check call State via dumpsys telephony.registry
    ...    - Arguments: State (RINGING/ACTIVATED/IDLE)
	${i}    Set Variable    0
    ${callResult}    Set Variable    ${EMPTY}
    ${findLine}    Set Variable    ${EMPTY}
	Log With Time    - Check Testphone Call State ${State} -
    Select Device    ${PHONE_SN}
    IF    '${State}' == 'RINGING'
        FOR    ${i}    IN RANGE    180
            ${result}=    Shell    dumpsys telephony.registry
            ${flag_check}   Run Keyword And Return Status    Should Contain    ${result}    mCallState=1
            IF    '${flag_check}' == 'True'
            # ${findLine}=    Get Lines Containing String    ${result}    mCallState=1
            # IF    '${findLine}' != ''
                Log With Time    - Call state is Ringing -
                ${callResult}    Set Variable    True
                Exit For Loop
            ELSE
                ${callResult}    Set Variable    Fail
            END
        END
    ELSE IF    '${State}' == 'ACTIVATED'
        FOR    ${i}    IN RANGE    60
            ${result}=    Shell    dumpsys telephony.registry
            # ${findLine}=    Get Lines Containing String    ${result}    mCallState=2
            ${flag_check}   Run Keyword And Return Status    Should Contain    ${result}    mCallState=2
            IF    '${flag_check}' == 'True'
                Log With Time    - Call state is Active -
                ${callResult}    Set Variable    True
                Exit For Loop
            ELSE
                ${callResult}    Set Variable    Fail
            END
        END
    ELSE IF    '${State}' == 'INACTIVATED'
        FOR    ${i}    IN RANGE    60
            ${result}=    Shell    dumpsys telephony.registry
            # ${findLine}=    Get Lines Containing String    ${result}    mCallState=0
            ${flag_check}   Run Keyword And Return Status    Should Contain    ${result}    mCallState=0
            IF    '${flag_check}' == 'True'
            # IF    '${findLine}' != ''
                Log With Time    - Call state is INACTIVATED -
                ${callResult}    Set Variable    True
                Exit For Loop
            ELSE
                ${callResult}    Set Variable    Fail
            END
        END
    END
    
    # ${result}    Run Keyword And Return Status    Should Be Empty    ${findLine}

    IF    '${callResult}' == 'True'
        Log    ${findLine}    console=yes
        Log With Time    - Call state is ${State} as expected -
    ELSE
        Run Keyword And Continue On Failure    Fail    Testphone call state is not ${State} state!!!
    END
    [RETURN]    ${callResult}


#my5.nguyen
Send incoming call to the phone  
    [Documentation]    `Send incoming call to the phone` step
    ${cmd_ADB_to_make_a_call}    Set Variable    am start -a android.intent.action.CALL -d tel:${phone_number}
    Wait Until Keyword Succeeds    3x    5s    Send and Find ADB String    ${cmd_ADB_to_make_a_call}     2     Starting: Intent    ${PHONE_SN}

Setup phone number for test
    [Documentation]    `Setup phone number for test` step
    ...    - Set up phone number
	[Arguments]    ${phone_number}
    Send and Find ADB String    sldd am setprop eCall EuECallTestNumber ${phone_number}     2   prop:EuECallTestNumber     ${ADB_SERIAL}
    Sleep    1
    Send ADB String    sync    ${ADB_SERIAL}
    Sleep    1
    # Send ADB String    reboot -f    ${ADB_SERIAL}
    # Sleep    90
    
Ignore 2 First Calls
    [Documentation]    `Ignore 2 First Calls` steps
    ...    - Check for 1st call then wait unitl it stops
    ...    - Check for 2nd call then wait unitl it stops
    Log With Time   - Ignore 1st Call
    Check Testphone Call State    RINGING    # 1min
    Sleep    60s    Wait for 1st Call to stop

    Log With Time   - Wait for 2nd Call
    Sleep    15s    Wait for 2nd Call

    Log With Time   - Ignore 2nd Call
    Check Testphone Call State    RINGING    # 1min
    Sleep    60s    Wait for 2nd Call to stop

Detect Airbag Signal
    [Documentation]    `Detect Airbag Signal` step
    [Arguments]    ${status}

    IF    '${status}' == 'Crash'
        ${flag_check}    Run Keyword And Return Status    Airbag Pattern    0    1
        Sleep    4
    ELSE IF    '${status}' == 'Normal'
        ${flag_check}    Run Keyword And Return Status    Airbag Pattern    0    0
        Sleep    2
    END
    Run Keyword If   ${flag_check}==False     Run Keyword And Continue On Failure    Fail    Detect Airbag Signal ${status} Fail

SOS Call Process Kill 
    [Documentation]    `SOS Call Process Kill` step
    Log With Time    - Send ADB String perform process kill
    ${flag_check}    Run Keyword And Return Status    Send ADB String    killall -6 eCall    ${ADB_SERIAL}
    Run Keyword If   ${flag_check}==False     Run Keyword And Continue On Failure    Fail    Send ADB String perform process kill fail
    Sleep    2


Check Tigris file TYT
    [Documentation]    `Check Tigris file TYT` step
    ...                - Check file Tigris was generated after send command to kill eCall application
    [Arguments]   ${Tigris_File_Check}
    ADB.Select Device    ${ADB_SERIAL}
    # send String(Command)
    ${result}=   ADB.Shell    ls /data/logger
    Sleep    2
    ${flag_check}    Run Keyword And Return Status    Should Contain    ${result}    ${Tigris_File_Check}
    Run Keyword If   ${flag_check}==False     Run Keyword And Continue On Failure    Fail    Check ${Tigris_File_Check} file Fail


Remove Tigris File generated
    [Documentation]    `Remove Tigris File generated` step
    ...               - Remove Tigris file generated by command pkill
    [Arguments]   ${Tigris_File_Check}
    Log With Time    - Send ADB String remove Tigris file generated by command pkill
    Send ADB String    rm -rf /data/logger/tigris_*    ${ADB_SERIAL}
    ADB.Select Device    ${ADB_SERIAL}
    # send String(Command)
    ${result}=   ADB.Shell    ls /data/logger
    Sleep    2
    Run Keyword And Continue On Failure    Should Not Contain    ${result}    ${Tigris_File_Check}


#=================================================================
# ETC Keyword
#=================================================================
Log with Keywords
    [Documentation]    `Log with Keywords` step
    ...    - output '=' in box shape
    ...    - output comment
    [Arguments]    ${comment}    ${symbol}
    ${comment}    Evaluate    '${comment}'.center(len('${comment}') + 2, ' ')
    ${box}    Evaluate    '${symbol}' * ${70}
    ${output}    Evaluate    '${comment}'.center(70, '${symbol}')
    Log    ${\n}${box}${\n}${output}${\n}${box}    console=yes

End of Procedure
    [Documentation]    `End of Procedure` step
    ...    - increasing the count
    ...    - find the time to end
    ...    - find the time spent on the test
    ...    - output the log
    [Arguments]    ${current count}    ${start time}

    Wait for DCM Booting Time

    ${current count}    Evaluate    ${current count} + 1
    ${end time}    Get Current Date
    ${during time}    Subtract Date From Date    ${end time}    ${start time}
    #EXPORT EXCEL FILE
    Export Excel File    ${current count}    ${start time}    ${end time}
    
    IF    ${current count} % 10 == 1
        Log with Keywords    ${current count}st cycle - ${during time}s    \#
    ELSE IF    ${current count} % 10 == 2
        Log with Keywords    ${current count}nd cycle - ${during time}s    \#
    ELSE IF    ${current count} % 10 == 3
        Log with Keywords    ${current count}rd cycle - ${during time}s    \#
    ELSE
        Log with Keywords    cth cycle - ${during time}s    \#
    END
    # ${new_end_line_AP}=    Get End Line        ${AP_LOG_PATH}
    # ${new_end_line_MCU}=    Get End Line        ${MCU_LOG_PATH}
    # Set Global Variable    ${end_line_AP}    ${new_end_line_AP}
    # Set Global Variable    ${end_line_MCU}    ${new_end_line_MCU}
    # Log With Time    - endLine AP ${end_line_AP}
    # Log With Time    - endLine MCU ${end_line_MCU}
    RETURN    ${current count}

Wait Random Time
    [Documentation]    `Wait Random Time` step
    [Arguments]    ${min}    ${max}    ${step}=1

    ${step}    Evaluate    float(${step})
    ${random_time}    Evaluate    random.uniform(${min}, ${max})
    ${delay}    Evaluate    ${random_time} - (${random_time} % ${step})
    ${delay}=    Evaluate    round(${delay}, len(str(${step}).split('.')[1]))   # Round Delay
    Log With Time    - Wait ${delay} sec -
    Sleep    ${delay}

Create Excel File to Save Result
    [Documentation]    `Create Excel File` step
    ...            - Create excel file path to save data after testing
    [Arguments]    ${test_case_name}
    ${dir_excel_file}    Create Excel File Empty    ${test_case_name}    ${dir_excel_file}
    Set Global Variable    ${dir_excel_file}
  
#my5.nguyen
Export Excel File
    [Documentation]    'Export Excel File' step
    [Arguments]    ${current count}    ${start time}    ${end time}
    Log    ${TEST_NAME}
    # ${TESTCASE_NAME}    ${TEST_ID}    Split String    ${TEST_NAME}    ${SPACE}
    ${list}    Split String    ${TEST_NAME}    _
    ${TEST_ID}    Set Variable    ${list}[-1]
    @{my_list}    Set Variable    ${list}[0:-1]
    ${TESTCASE_NAME}    Catenate    SEPARATOR=_    @{my_list}   
    Log    ${current count}
    #get result run robot
    ${Result_Test}    Set Variable    'NONE'
    @{list_data_export_excel}    Create List    ${TEST_ID}    ${TESTCASE_NAME}    ${current count}     ${TEST TAGS}[-1]    
    ...    ${start_time}    ${end_time}    ${Result_Test}
    #collected data for update in excel file
    ${data}    Update Data   ${list_data_export_excel}
    #insert data in excel file
    Insert Data In Excel File    ${dir_excel_file}    ${data}
    ${current count}    Evaluate    ${current count} + 1
    ${during time}    Subtract Date From Date    ${end time}    ${start time}

#phong2.tran
Log with Sleep
    [Documentation]    `Log with Sleep` step
    ...    - wait for delay
    ...    - If delay >= 2h: log every 30 minutes
    ...    - If delay >= 10m: log every 5 minutes
    ...    - If delay < 10m: log every 10 seconds
    [Arguments]    ${delay}
    ${delay}=    robot.utils.Timestr To Secs    ${delay}
    
    IF    ${delay} >= 7200
        ${log_interval} =    Set Variable    1800
    ELSE IF    ${delay} >= 600
        ${log_interval} =    Set Variable    300
    ELSE
        ${log_interval} =    Set Variable    10
    END
    
    ${next_log_time} =    Set Variable    ${delay}
    
    WHILE    ${delay} > 0    limit=NONE    
        IF    ${delay} == ${next_log_time}
            ${remaining_time}=    robot.utils.Secs To Timestr    ${delay}
            Log    Time remaining: ${remaining_time}    console=yes
            ${next_log_time}=    Evaluate    max(${delay} - ${log_interval}, 0)
        END
        Sleep    1
        ${delay}=    Evaluate    ${delay} - 1
    END

# phong2.tran
Precondition Create Log Path
    [Arguments]    ${MODEL}
    [Documentation]    `Precondition Create Log Path` step
    ...    -Create Log path
    ...    -Input param is  MODEL
    #=================================================================
    # LOGGING Folder Path
    #=================================================================
    # to bug fix for the space name for the model
    ${MODEL_NAME}=       Evaluate    '${MODEL}'.replace(' ','_')
    ${currtime}=          Get Current Date    result_format=%Y-%m-%d_%H_%M_%S
    
    ${check_rf_logs_dir}=    Run Keyword And Ignore Error    Set Variable    ${RF_Logs_Dir}
    IF    '${check_rf_logs_dir}[0]' == 'FAIL'
        ${RF_Logs_Dir}=       Join Path    ./RF_TESTLOG/${MODEL_NAME}/${TEST NAME}_${currtime}
    END
    
    ${uart_path}=         Join Path    ${RF_Logs_Dir}    UART
    ${canat_path}=        Join Path    ${RF_Logs_Dir}    CANAT
    ${root_crash_path}=   Join Path    ${RF_Logs_Dir}    DATA_LOGGER
    ${dlt_path}=          Join Path    ${RF_Logs_Dir}    DLT
    ${mem_path}=          Join Path    ${RF_Logs_Dir}    MEMCHK
    ${excel_path}=        Join Path    ${RF_Logs_Dir}    EXCEL_FILE

    Log With Time    - Data ${RF_Logs_Dir}
    #=================================================================
    # LOGGING File Path tmp
    #=================================================================
    ${ap_log_path_tmp}=    Join Path    ${uart_path}          ${TEST NAME}_AP.log
    ${mcu_log_path_tmp}=   Join Path    ${uart_path}          ${TEST NAME}_MCU.log
    ${crash_path}=         Join Path    ${root_crash_path}
    ${canat_log_path}=     Join Path    ${canat_path}
    ${dlt_log_path}=       Join Path    ${dlt_path}
    ${dir_excel_file}=     Join Path    ${excel_path}

    Set Global Variable    ${AP_LOG_PATH}       ${ap_log_path_tmp}
    Set Global Variable    ${MCU_LOG_PATH}      ${mcu_log_path_tmp}
    Set Global Variable    ${CANAT_LOG_PATH}    ${canat_log_path}
    Set Global Variable    ${CRASH_PATH}        ${crash_path}
    Set Global Variable    ${DLT_LOG_PATH}      ${dlt_log_path}
    Set Global Variable    ${RF_LOG_DIR}        ${RF_Logs_Dir}
    Set Global Variable    ${mem_path_local}    ${mem_path}
    Set Global Variable    ${dir_excel_file}

    Create Directory    ${RF_Logs_Dir}
    Create Directory    ${uart_path}
    Create Directory    ${canat_path}
    Create Directory    ${canat_log_path}
    Create Directory    ${root_crash_path}
    Create Directory    ${crash_path}
    Create Directory    ${dlt_path}
    Create Directory    ${mem_path}
    Create Directory    ${dir_excel_file}

    Log With Time    - Log path create done
