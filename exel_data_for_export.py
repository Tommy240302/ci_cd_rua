####################################################
############# VARIABLE FOR EXFORT FILE #############
####################################################
export_app_dir = "d:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/resource/ExportExcelResult.py"
output_folder_path = "D:/Test_Result"

####################################################
####### VARIABLE FOR INSERT DATA TO DATABASE #######
####################################################
insert_data_file_path = r"D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/resource/VSV_Insert_Testresult_to_DB_v1.8.exe"
code_to_type = {
    "I": "Stability",       # Internal
    "V": "Comfirm_Test",    # Verify ticket
    "F": "Official_Test",   # Full Validation
    "R": "Request_Test",    # Request Test (DEV Request)
}
flag_insert_data_to_database = "True"
flag_insert_multi_csv_file = "False"
flag_update_excel_file_and_convert = "False"
flag_convert_json_file = "False"

flag_auto_send_mail = "True"
receiver = 'sam.tran@lge.com, thu.mai@lge.com, phuckhanh.tranvu@lgepartner.com, minhquang.laikhac@lge.com'

####################################################
########### INPUT DATA FOR EACH TEST RUN ###########
####################################################
project_id = "AVT_PRJ_006"

sw_version = "LG-S810aa3636-01"

test_environment = "TYT19MC_V2"

execution_type = "F"

assignee = "minhquang.laikhac"

csv_file_path_list = [
        "D:/Test_Result/Official_Test/19MC_Stress_GNSS_01_20250725_163429/EXCEL_FILE/19MC_Stress_GNSS_01_25400302_20250725_163815.csv",
]

testcase_list = [

        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/DCM_Reset/19MC_Stress_DR_06.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/GNSS/19MC_Stress_GNSS_02.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_04.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_05.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_06.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_22.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_23.robot",
        "D:/workspace/my5.nguyen/toyota_tele_19mc_rf_scripts/scripts/PowerMode/19MC_Stress_PM_24.robot",
        
]
