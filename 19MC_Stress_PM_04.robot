** Settings ***
Force Tags      PM
Resource         ../../resource/Toyota_19MC.resource
Test Setup      Test-Precondition
Test Teardown   Test-Postcondition
Test Timeout    18h
#------------------------------------
# TC_ID: 25510442
# Created By: my5.nguyen
# Created Date:
# Updated Date:
# Updated By:
#------------------------------------
*** Variables ***
${CPU_INDEX}        0
${i}                0
# ${testCount}        1

*** Test Cases ***
# SressTest [Priority : 1]
19MC_Stress_PM_04_25510442
    Log With Time    ==================================================================
    Log With Time    ==================================================================
    Log With Time  ★★★★ Test start ★★★★

    FOR    ${current_count}    IN RANGE    ${testCount}
        
        Log With Time   - Cycle : ${current_count+1}/${testCount} -
        ${start time}    Get Current Date
        
        Run Keyword And Continue On Failure    Check Devices in TYT    ${ADB_SERIAL}

        # Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    3x    5s    Check BUB voltage value    
        
        SLEEP  1

        # Clear DTC
        
        Bench Turn the ignition key     OFF

        CANat Send ACC CAN msg    OFF

        Send All CAN Message Stop

        CANat Send Wakeup Signal CAN msg

        Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    7x    5s     Bench Check input current    Wake up Mode

        SLEEP  2

        Bench Turn the ignition key     ON

        CANat Send ACC CAN msg    ON

        Send All CAN Message Stop

        Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    7x    5s     Bench Check input current    Normal Mode

        Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    7x    10s     Check DCM Power State changes    NORMAL

        Wait for DCM Booting Time    60

        # Send MCU String    Reset Factor

        SLEEP  1

        Check rmnet data    ADB

        End of Procedure    ${current_count}    ${start time}
    END

    Log With Time    ★★★★ Test end : ${current_count+1}th ★★★★
    Log With Time    ==================================================================
    Log With Time   ==================================================================
    
