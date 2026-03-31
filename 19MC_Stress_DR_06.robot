** Settings ***
Force Tags      DR
Resource         ../../resource/Toyota_19MC.resource
Test Setup      Test-Precondition
Test Teardown   Test-Postcondition
Test Timeout    18h
#------------------------------------
# TC_ID: 25400310
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
19MC_Stress_DR_06_25400310
    Log With Time    ==================================================================
    Log With Time    ==================================================================
    Log With Time  ★★★★ Test start ★★★★

    FOR    ${current_count}    IN RANGE    ${testCount}
        
        Log With Time   - Cycle : ${current_count+1}/${testCount} -
        ${start time}    Get Current Date
        
        # Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    3x    5s    Check BUB voltage value
        
        # SLEEP  1

        Clear DTC

        # MCU Platform reset

        IGN    OFF

        Random Time    1    120

        IGN    ON
        
        SLEEP  60

        ${flag_check}    Run Keyword And Return Status    Check Devices in TYT    ${ADB_SERIAL}

        Run Keyword If    ${flag_check}==False    Wait for ADB Device

        
        SLEEP  1

        # Send MCU String    Reset Factor

        SLEEP  5

        Run Keyword And Return Status    Check rmnet data    ADB

        End of Procedure    ${current_count}    ${start time}
    END

    Log With Time    ★★★★ Test end : ${current_count+1}th ★★★★
    Log With Time    ==================================================================
    Log With Time   ==================================================================
