** Settings ***
Force Tags      GNSS
Resource         ../../resource/Toyota_19MC.resource
Test Setup      Test-Precondition
Test Teardown   Test-Postcondition
Test Timeout    18h
#------------------------------------
# TC_ID: 25400303
# Created By: my5.nguyen
# Created Date: 21/08/2024
# Updated Date:
# Updated By:
#------------------------------------
*** Variables ***
${CPU_INDEX}        0
${i}                0
# ${testCount}        1

*** Test Cases ***
# SressTest [Priority : 1]
19MC_Stress_GNSS_02_25400303
    Log With Time    ==================================================================
    Log With Time    ==================================================================
    Log With Time  ★★★★ Test start ★★★★

    FOR    ${current_count}    IN RANGE    ${testCount}
        
        Log With Time   - Cycle : ${current_count+1}/${testCount} -
        ${start time}    Get Current Date

        # Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    3x    5s    Check BUB voltage value
        
        # SLEEP  1

        Clear DTC
        
        Bench Turn the ignition key     OFF

        CANat Send ACC CAN msg    OFF

        Sleep    10
        
        CANat Send ACC CAN msg    ON

        Bench Turn the ignition key     ON

        Wait for DCM Booting Time
        
        Wait Until Keyword Succeeds    2x    5s    Send ADB String    sldd loc setGPSStart cold    ${ADB_SERIAL}

        Run Keyword And Continue On Failure    Check GPS fixed

        SLEEP  1

        # Run Keyword And Continue On Failure     Send MCU String    Reset Factor

        SLEEP  5

        Run Keyword And Continue On Failure     Check rmnet data    ADB

        End of Procedure    ${current_count}    ${start time}
    END

    Log With Time    ★★★★ Test end : ${current_count+1}th ★★★★
    Log With Time    ==================================================================
    Log With Time   ==================================================================
