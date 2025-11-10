# SortLog_Analyse

This tool reads serial numbers from a CSV file to download attachments from ETQ, generate a SUFA–Serial Number mapping, and extract key metrics from ZIP files containing the keyword "Sorting" into a structured summary CSV.

## Version

Current version: **v1.0.0**

## Contributors

- Darvin Lemus – JavaScript
- Anyi Wang – Python and Scripts Intergration

## Quick Setup

### Step 1: Install Dependencies
```bash
npm install playwright ini
```

### Step 2: Prepare Your Data
- Create a CSV file with serial numbers (one per line)
- No header needed - just the serial numbers

### Step 3: Configure Settings
Edit `config.ini` with your settings:
```ini
[login_production]
download_dir = your Downloads path
chrome_path = your chrome.exe path
qis_un = your_username@domain.com
qis_pw = your_password
csv_file = your_serial_numbers.csv
```

### Step 4: Run the Tool
```bash
node ETQ_Download.js production config.ini
```

### Step 5: Zoom Out
- Wait for the terminal prompt
- Zoom out to **75%** (or **33%** for laptop screens)
- Press Enter to continue

## What It Does
- Automatically logs into ETQ
- Processes each serial number from your CSV
- Downloads attachments to organized folders
- Finds SUFA Number and generate a SUFANumber - serial nmber mapping csv file
- Shows Download progress: 
    
    1/66 Processing <SerialNumber>
    Finds SUFA Number <SUFANumber> 
    All serial numbers processed! Download completed.            
    
- Automatically extracts logs from ZIP files
- Parses and analyzes log content
- Generates a summary CSV report 
- Show Log Analysis process: 
    
    🧩 Running Python log analysis...
    Results saved to: `[download_dir]/logs/Summary.csv`
    Total ZIPs processed <number>
    ALL_P_ ZIPs: <number> |ALL_F_ ZIPs: <number> |ALL_P_and_F_ ZIPs: <number> |TxT Only: <number> |Without Basic: <number> |Without Production: <number> |With one .sh per test: <number> |Without .sh per test: <number> |
    
## Files Created
- `logs/` folder with subfolders for each serial number, Serial_SUFA_Mapping.csv and Summary.csv
- Downloaded files organized by serial number

## Notes
- Script stops after processing all serial numbers once
- Downloads are saved to `C:/Users/[username]/Downloads` then moved to logs folder
- Browser window opens automatically (not headless)
