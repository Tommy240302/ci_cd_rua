import subprocess
import os
from datetime import datetime
from excel_data_for_export import *


def run_robot_and_export(output_folder,testcase_dir,export_app_dir):
    #Run TSs and export excel file
    get_date = datetime.now()
    get_date = get_date.strftime("%Y%m%d_%H%M%S")
    test_case_name = os.path.splitext(os.path.basename(testcase_dir))[0]
    test_type = code_to_type.get(execution_type, "Unknown")
    output_dir = f"{output_folder}/{test_type}/{test_case_name}_{get_date}"
    

    #Run TSs and export excel file
    subprocess.run([
        "robot",
        "--outputdir", f"{output_dir}",
        "--variable", f"RF_Logs_Dir:{output_dir}",
        f"{testcase_dir}"
    ])

    #Update test result from output.xml file to excel file, convert excel file to csv file and push csv file to database
    subprocess.run([
        "python", 
        f"{export_app_dir}",
        f"{output_dir}/output.xml"],
        start_new_session= True
    )

def import_data_to_database():
    subprocess.run([
    "python", 
    f"{export_app_dir}"]
    )

if __name__ == "__main__":
    if flag_insert_multi_csv_file == "True":
        import_data_to_database()
    else:
        for testcase_dir in testcase_list:
            run_robot_and_export(output_folder_path,testcase_dir,export_app_dir)
