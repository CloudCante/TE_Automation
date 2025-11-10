import os
import zipfile
import csv

def list_subfolders_and_summary(root_folder, name_part, output_csv):
    results = []
    p_zip_files = set()
    f_zip_files = set()
    p_f_zip_files = set()
    txt_only_zips = set()
    no_basic_zips = set()
    one_sh_zips = set()
    no_sh_zips = set()
    no_production_zips = set()

    all_zip_results = []  # to track per-ZIP info for summary later

    for folder_path, _, files in os.walk(root_folder):
        for file in files:
            if file.endswith(".zip") and name_part in file:
                zip_path = os.path.join(folder_path, file)
                zip_name = os.path.basename(zip_path)
                try:
                    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                        all_entries = zip_ref.namelist()
                        # collect all folder entries that include 'Production'
                        Production_folders = sorted({e for e in all_entries if e.endswith('/') and 'Production' in e})

                        # remove any Production folder that is nested under another Production folder
                        top_production_folders = [
                            p for p in Production_folders
                            if not any((q != p and p.startswith(q)) for q in Production_folders)
                        ]

                        Basic_folders = sorted({e for e in all_entries if e.endswith('/') and 'Basic' in e})
                        all_txt = all(e.endswith('.txt') or e.endswith('.log') for e in all_entries if not e.endswith('/'))

                        if all_txt:
                            txt_log_files = [e for e in all_entries if e.endswith('.txt') or e.endswith('.log')]
                            results.append([zip_path, "Only txt data", ", ".join(txt_log_files)])
                            txt_only_zips.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "txt-only"})
                            continue
                        elif not Basic_folders:
                            results.append([zip_path, "Basic not exists"])
                            no_basic_zips.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "Basic_not_exists"})
                            continue
                        elif not Production_folders:
                            results.append([zip_path, "Production not exists"])
                            no_production_zips.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "Production_not_exists"})
                            continue

                        subfolder_records = []
                        for each_folder in top_production_folders:
                            subfolders = set()
                            for entry in all_entries:
                                if entry.startswith(each_folder) and entry != each_folder:
                                    relative = entry[len(each_folder):]
                                    parts = relative.split('/')
                                    if len(parts) > 1 and parts[0]:
                                        subfolders.add(parts[0])

                            if subfolders:
                                for sub in sorted(subfolders):
                                    results.append([zip_path, f"{each_folder}{sub}/"])
                                    subfolder_records.append(f"{each_folder}{sub}/")
                            else:
                                results.append([zip_path, f"{each_folder}(no subfolders)"])
                                subfolder_records.append(f"{each_folder}(no subfolders)")

                        # Determine ZIP type (P, F, or other)
                        if all("_P_" in s for s in subfolder_records if "Production" in s):
                            p_zip_files.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "all_P"})
                        elif all("_F_" in s for s in subfolder_records if "Production" in s):
                            f_zip_files.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "all_F"})
                            for subfolder_path in subfolder_records:
                                nautilus_path = os.path.join(subfolder_path, "nautilus/")
                                sh_files = [e for e in all_entries if e.startswith(nautilus_path) and e.endswith(".sh")]
                                if len(sh_files) == 1:
                                    one_sh_zips.add(zip_name)
                                    results.append([zip_path, f"Only one .sh file in {subfolder_path}"])
                                elif len(sh_files) > 1:
                                    results.append([zip_path, f"Multiple .sh files in {subfolder_path}"])
                                else:
                                    no_sh_zips.add(zip_name)
                                    results.append([zip_path, f"No .sh files in {subfolder_path}"])
                        else:
                            p_f_zip_files.add(zip_name)
                            all_zip_results.append({"zip": zip_path, "type": "normal"})

                except zipfile.BadZipFile:
                    results.append([zip_path, "(Invalid or corrupted ZIP file)"])

    # Write main CSV
    with open(output_csv, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)

        # Summary section
        writer.writerow([])
        writer.writerow(["=== SUMMARY ==="])
        writer.writerow(["Total ZIPs processed", len(set(r["zip"] for r in all_zip_results))])
        writer.writerow(["ZIPs with ALL folders containing _P_", len(p_zip_files)])
        writer.writerow(["ZIPs with ALL folders containing _F_", len(f_zip_files)])
        writer.writerow(["ZIPs with folders contains _P_ and _F_", len(p_f_zip_files)])
        writer.writerow(["all_F ZIPs with one .sh per test", len(one_sh_zips)])
        writer.writerow(["all_F ZIPs without .sh per test", len(no_sh_zips)])
        writer.writerow(["ZIPs with txt data only", len(txt_only_zips)])
        writer.writerow(["ZIPs without Basic folder", len(no_basic_zips)])
        writer.writerow(["ZIPs without Production folder", len(no_production_zips)])

        # Separate page (section) listing ZIPs with _P_
        writer.writerow([])
        writer.writerow(["=== ZIPs with ALL folders containing _P_ ==="])
        for pzip in sorted(p_zip_files):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs with _F_
        writer.writerow([])
        writer.writerow(["=== ZIPs with ALL folders containing _F_ ==="])
        for pzip in sorted(f_zip_files):
            writer.writerow([pzip])
        
        # Separate page (section) listing ZIPs with _P_ and _F_
        writer.writerow([])
        writer.writerow(["=== ZIPs with folders contains _P_ and _F_ ==="])
        for pzip in sorted(p_f_zip_files):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs with txt data only
        writer.writerow([])
        writer.writerow(["=== ZIPs with txt data only==="])
        for pzip in sorted(txt_only_zips):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs without Basic folder
        writer.writerow([])
        writer.writerow(["=== ZIPs without Basic folder==="])
        for pzip in sorted(no_basic_zips):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs without Production folder
        writer.writerow([])
        writer.writerow(["=== ZIPs without Production folder ==="])
        for pzip in sorted(no_production_zips):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs with one .sh
        writer.writerow([])
        writer.writerow(["=== ZIPs with one .sh ==="])
        for pzip in sorted(one_sh_zips):
            writer.writerow([pzip])

        # Separate page (section) listing ZIPs without .sh
        writer.writerow([])
        writer.writerow(["=== ZIPs without .sh ==="])
        for pzip in sorted(no_sh_zips):
            writer.writerow([pzip])
        
        writer.writerow(["ZIP File Path", "Production Folder / Subfolder"])
        writer.writerows(results)

    print(f"\n Results saved to: {output_csv}")
    print(f"Total ZIPs processed: {len(set(r['zip'] for r in all_zip_results))}")
    print(
        f"ALL_P_ ZIPs: {len(p_zip_files)} |" 
        f"ALL_F_ ZIPs: {len(f_zip_files)} |"
        f"ALL_P_and_F_ ZIPs: {len(p_f_zip_files)} |" 
        f"TxT Only: {len(txt_only_zips)} |" 
        f"Without Basic: {len(no_basic_zips)} |" 
        f"Without Production: {len(no_production_zips)} |"
        f"With one .sh per test: {len(one_sh_zips)} |"
        f"Without .sh per test: {len(no_sh_zips)} |"
        )


# Main
if __name__ == "__main__":
    import sys
    if len(sys.argv) < 4:
        print("Usage: python LogAnalyse.py <log_folder> <keyword> <output_csv>")
        sys.exit(1)
    log_folder = sys.argv[1]                       
    keyword = sys.argv[2]                          # ZIP filename keyword
    output_file = sys.argv[3]

    list_subfolders_and_summary(log_folder, keyword, output_file)


