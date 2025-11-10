const { chromium } = require('playwright');
const fs = require('fs');
const ini = require('ini');
const readline = require('readline');
const { exec } = require("child_process")
const path = require("path")

const logFolder = path.join(__dirname, "logs");
const keyword = "Sorting";
const outputCSV = path.join(logFolder, "Summary.csv");

// after all downloads complete:
function analyzeLogs() {
  console.log("🧩 Running Python log analysis...");
  const cmd = `python LogAnalyse.py "${logFolder}" "${keyword}" "${outputCSV}"`;

  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      console.error("❌ Error running analysis:", error.message);
      return;
    }
    if (stderr) console.error("⚠️ Python warnings:", stderr);
    console.log(stdout);
    console.log("✅ Log analysis completed!");
  });
}
/**
 * ETQ Automation Script - Clean version without debug output
 */

// Configuration
let config;
let mode;

/**
 * Parse command line arguments and load configuration
 */
function loadConfig() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.error('Usage: node ETQ_Download.js <mode> <config_file>');
        console.error('Example: node ETQ_Download.js production config.ini');
        process.exit(1);
    }
    
    mode = args[0];
    const configFile = args[1];
    
    try {
        const configContent = fs.readFileSync(configFile, 'utf-8');
        config = ini.parse(configContent);
    } catch (error) {
        console.error(`Error loading config file: ${error.message}`);
        process.exit(1);
    }
}

/**
 * Get list of already processed serial numbers by checking logs folder
 */
function getProcessedSerialNumbers() {
    const logsDir = path.join(__dirname, "logs");
    const processed = [];
    
    try {
        if (fs.existsSync(logsDir)) {
            const items = fs.readdirSync(logsDir);
            for (const item of items) {
                const itemPath = `${logsDir}/${item}`;
                if (fs.statSync(itemPath).isDirectory()) {
                    const files = fs.readdirSync(itemPath);
                    if (files.length > 0) {
                        processed.push(item);
                    }
                }
            }
        }
    } catch (error) {
        // Silent error handling
    }
    
    return processed;
}

/**
 * Get list of unprocessed serial numbers
 */
function getUnprocessedSerialNumbers(allSerialNumbers) {
    const processed = getProcessedSerialNumbers();
    const unprocessed = allSerialNumbers.filter(serial => !processed.includes(serial));
    return unprocessed;
}

/**
 * Wait for user input to close
 */
function waitForUserInput() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    
    rl.question('', () => {
        rl.close();
        process.exit(0);
    });
}

/**
 * Wait for all downloads to complete and move them to serial number folder
 */
async function waitForDownloadsAndMove(serialNumber, pendingDownloads, completedDownloads) {
    // Wait for all pending downloads to complete
    let attempts = 0;
    const maxAttempts = 30;
    let lastPendingCount = pendingDownloads.length;
    let stableCount = 0;
    
    while (pendingDownloads.length > 0 && attempts < maxAttempts) {
        attempts++;
        const currentPendingCount = pendingDownloads.length;
        
        if (currentPendingCount === lastPendingCount) {
            stableCount++;
            if (stableCount >= 5) {
                break;
            }
        } else {
            stableCount = 0;
            lastPendingCount = currentPendingCount;
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    // Create serial number folder in logs directory
    const logsDir = path.join(__dirname, "logs");
    const serialNumberDir = `${logsDir}/${serialNumber}`;
    
    try {
        if (!fs.existsSync(logsDir)) {
            fs.mkdirSync(logsDir, { recursive: true });
        }
        
        if (!fs.existsSync(serialNumberDir)) {
            fs.mkdirSync(serialNumberDir, { recursive: true });
        }
        
        // Move all completed downloads to the serial number folder
        let movedCount = 0;
        for (const download of completedDownloads) {
            try {
                const sourcePath = download.downloadPath;
                const fileName = download.fileName;
                const targetPath = `${serialNumberDir}/${fileName}`;
                
                if (fs.existsSync(sourcePath)) {
                    fs.copyFileSync(sourcePath, targetPath);
                    movedCount++;
                    fs.unlinkSync(sourcePath);
                }
            } catch (moveError) {
                // Silent error handling
            }
        }
        
        return true;
        
    } catch (error) {
        return false;
    }
}

/**
 * Enter serial number in the NVSN column
 */
async function enterSerialNumber(page, serialNumber) {
    try {
        // Wait for the grid to be fully loaded
        await page.waitForSelector('ag-grid-angular', { timeout: 10000 });
        await page.waitForSelector('.ag-floating-filter-input', { timeout: 10000 });
        
        // Look for the floating filter inputs
        const floatingFilterInputs = await page.$$('.ag-floating-filter-input');
        
        if (floatingFilterInputs.length > 0) {
            // Target the NVSN (Manual Input) column (12th row, index 11)
            const targetIndex = 11;
            const targetField = floatingFilterInputs[targetIndex];
            
            // Enhanced field clearing
            await targetField.click();
            await page.keyboard.press('Control+a');
            await page.keyboard.press('Delete');
            await targetField.fill('');
            
            // Ensure it's really empty
            const currentValue = await targetField.inputValue();
            if (currentValue && currentValue.trim() !== '') {
                await targetField.click();
                await page.keyboard.press('Control+a');
                await page.keyboard.press('Delete');
                await targetField.fill('');
            }
            
            // Enter the new serial number
            await targetField.fill(serialNumber.toString());
            await targetField.press('Enter');
            
            return true;
        }
        
        return false;
    } catch (error) {
        return false;
    }
}

/**
 * Check if we're back at the login page
 */
async function isAtLoginPage(page) {
    try {
        const loginButton = await page.$('[data-id="LOGIN_USING_ANOTHER_ACCOUNT"]');
        if (loginButton) {
            return true;
        }
        
        // Check for other common login page indicators
        const loginIndicators = [
            'text=Login',
            'text=Sign in',
            'text=Log in',
            'input[name="username"]',
            'input[name="password"]',
            'input[type="password"]',
            '.login-form',
            '#login-form',
            '[class*="login"]',
            'text=/username/i',
            'text=/password/i'
        ];
        
        let foundLoginIndicators = [];
        for (const selector of loginIndicators) {
            const element = await page.$(selector);
            if (element) {
                foundLoginIndicators.push(selector);
            }
        }
        
        return foundLoginIndicators.length > 0;
    } catch (error) {
        return false;
    }
}

/**
 * Perform login if we're at the login page
 */
async function performLogin(page) {
    try {
        // Wait for login elements to be ready
        try {
            await page.waitForSelector('[data-id="LOGIN_USING_ANOTHER_ACCOUNT"]', { timeout: 5000 });
        } catch (waitError) {
            // Check for alternative login buttons
            const altLoginSelectors = [
                'text=Login as a non-SSO user',
                'text=Login',
                'text=Sign in',
                'text=Log in',
                '[data-testid*="login"]',
                '.login-button',
                '#login-button',
                'button:has-text("Login")',
                'button:has-text("Sign in")'
            ];
            
            let foundLoginElement = false;
            for (const selector of altLoginSelectors) {
                const element = await page.$(selector);
                if (element) {
                    foundLoginElement = true;
                    break;
                }
            }
            
            if (!foundLoginElement) {
                throw new Error('No login elements found on page');
            }
        }
        
        // Click login button
        try {
            await page.click('[data-id="LOGIN_USING_ANOTHER_ACCOUNT"]');
            await page.waitForTimeout(1000);
        } catch (clickError) {
            throw clickError;
        }
        
        // Fill in credentials
        await page.waitForTimeout(2000);
        
        const usernameSelectors = [
            '#_FIELD--USER_NAME input[data-id="value"]',
            '#_FIELD--USER_NAME input[type="text"]',
            '#_FIELD--USER_NAME input',
            'input[data-id="value"]',
            'input[name="username"]',
            'input[name="user"]',
            'input[type="text"]',
            '#username',
            '#user',
            'input[placeholder*="username"]',
            'input[placeholder*="user"]',
            'input[placeholder*="email"]',
            'input[placeholder*="login"]'
        ];
        
        let usernameField = null;
        let usedUsernameSelector = null;
        
        for (const selector of usernameSelectors) {
            usernameField = await page.$(selector);
            if (usernameField) {
                usedUsernameSelector = selector;
                break;
            }
        }
        
        if (!usernameField) {
            throw new Error('Username field not found');
        }
        
        const username = config[`login_${mode}`].qis_un;
        if (!username) {
            throw new Error(`Username not found in config for mode: ${mode}. Available config keys: ${Object.keys(config).join(', ')}`);
        }
        await page.fill(usedUsernameSelector, username);
        
        const passwordSelectors = [
            '#_FIELD--PASSWORD input[data-id="value"]',
            '#_FIELD--PASSWORD input[type="text"]',
            '#_FIELD--PASSWORD input',
            'input[data-id="value"]',
            'input[name="password"]',
            'input[type="password"]',
            'input[type="text"]',
            '#password',
            '#pass',
            'input[placeholder*="password"]',
            'input[placeholder*="pass"]'
        ];
        
        let passwordField = null;
        let usedPasswordSelector = null;
        
        for (const selector of passwordSelectors) {
            passwordField = await page.$(selector);
            if (passwordField) {
                usedPasswordSelector = selector;
                break;
            }
        }
        
        if (!passwordField) {
            throw new Error('Password field not found');
        }
        
        const password = config[`login_${mode}`].qis_pw;
        if (!password) {
            throw new Error(`Password not found in config for mode: ${mode}. Available config keys: ${Object.keys(config).join(', ')}`);
        }
        await page.fill(usedPasswordSelector, password);
        
        // Submit login
        const submitSelectors = [
            '.login-submit-button',
            'button[type="submit"]',
            'input[type="submit"]',
            '.submit-button',
            '#submit',
            'button:has-text("Login")',
            'button:has-text("Sign in")',
            'button:has-text("Submit")',
            'button:has-text("Log in")',
            'input[value*="Login"]',
            'input[value*="Sign in"]',
            'input[value*="Submit"]'
        ];
        
        let submitButton = null;
        let usedSubmitSelector = null;
        
        for (const selector of submitSelectors) {
            submitButton = await page.$(selector);
            if (submitButton) {
                usedSubmitSelector = selector;
                break;
            }
        }
        
        if (!submitButton) {
            throw new Error('Submit button not found');
        }
        
        await page.click(usedSubmitSelector);
        await page.waitForTimeout(3000);
        
        // Verify we're logged in
        const stillAtLogin = await isAtLoginPage(page);
        if (!stillAtLogin) {
            return true;
        } else {
            // Look for error messages
            const errorSelectors = [
                '.error-message',
                '.alert-danger',
                '.login-error',
                '[class*="error"]',
                'text=/error/i',
                'text=/invalid/i',
                'text=/failed/i',
                'text=/incorrect/i',
                'text=/wrong/i'
            ];
            
            for (const selector of errorSelectors) {
                const errorElement = await page.$(selector);
                if (errorElement) {
                    const errorText = await errorElement.textContent();
                    throw new Error(`Login failed: ${errorText}`);
                }
            }
            
            return false;
        }
    } catch (error) {
        throw error;
    }
}

/**
 * Check if the page is in a usable state for processing serial numbers
 */
async function isPageReady(page) {
    try {
        // Check if we're at login page
        const atLoginPage = await isAtLoginPage(page);
        if (atLoginPage) {
            return false;
        }
        
        // Check if the main grid is visible and ready
        const gridElement = await page.$('ag-grid-angular');
        if (!gridElement) {
            return false;
        }
        
        // Check if filter inputs are available
        const filterInputs = await page.$$('.ag-floating-filter-input');
        if (filterInputs.length === 0) {
            return false;
        }
        
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Attempt to recover the page to a usable state
 */
async function recoverPage(page) {
    try {
        const atLoginPage = await isAtLoginPage(page);
        
        if (atLoginPage) {
            const loginSuccess = await performLogin(page);
            if (loginSuccess) {
                const mainURL = 'https://nvidia.etq.com/prod/rel/#/app/system/module/VACATION2/view/SUFA_COMPANY_DOCUMENTS_P';
                await page.goto(mainURL, { waitUntil: 'networkidle', timeout: 30000 });
                await page.waitForTimeout(3000);
                
                const pageReady = await isPageReady(page);
                if (pageReady) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            // Try refreshing the page
            try {
                await page.reload({ waitUntil: 'networkidle', timeout: 30000 });
                await page.waitForTimeout(5000);
                
                const pageReady = await isPageReady(page);
                if (pageReady) {
                    return true;
                } else {
                    return false;
                }
            } catch (refreshError) {
                return false;
            }
        }
    } catch (error) {
        return false;
    }
}

/**
 * Main function
 */
async function main() {
    const downloadsPath = config.login_production.download_dir;
    try {
        const browser = await chromium.launch({
            headless: false,
            args: [
                '--start-maximized',
                '--disable-web-security',
                '--disable-features=VizDisplayCompositor',
                '--disable-pdf-plugin',
                '--disable-extensions',
                '--disable-plugins',
                '--disable-default-apps',
                '--no-first-run',
                '--no-default-browser-check',
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-renderer-backgrounding',
                ...(mode === 'development' ? ['--proxy-server=10.62.58.181:8098'] : [])
            ]
        });
        
        try {
            const context = await browser.newContext({
                viewport: null,
                ignoreDefaultArgs: ['--enable-automation'],
                acceptDownloads: true,
                downloadPath: downloadsPath
            });
            
            context.on('page', page => {
                page.on('error', error => {
                    // Silent error handling
                });
                
                page.on('pageerror', error => {
                    // Silent error handling
                });
            });
            
            await context.setDefaultTimeout(30000);
            
            // Check if the download directory exists
            try {
                if (!fs.existsSync(downloadsPath)) {
                    fs.mkdirSync(downloadsPath, { recursive: true });
                }
            } catch (error) {
                // Silent error handling
            }
            
            const page = await context.newPage();
            await page.setViewportSize({ width: 1920, height: 1080 });
            
            // Track downloads for this serial number
            let pendingDownloads = [];
            let completedDownloads = [];
            
            // Set up download event handling
            page.on('download', async download => {
                const fileName = download.suggestedFilename();
                const downloadPath = `${downloadsPath}/${fileName}`;
                
                const downloadId = `${fileName}_${Date.now()}`;
                pendingDownloads.push({ download, fileName, downloadPath, id: downloadId });
                
                try {
                    await download.path();
                    await download.saveAs(downloadPath);
                    
                    if (fs.existsSync(downloadPath)) {
                        completedDownloads.push({ fileName, downloadPath });
                        pendingDownloads = pendingDownloads.filter(d => d.id !== downloadId);
                    }
                } catch (error) {
                    try {
                        const tempPath = download.path();
                        if (tempPath && fs.existsSync(tempPath)) {
                            fs.copyFileSync(tempPath, downloadPath);
                            completedDownloads.push({ fileName, downloadPath });
                            pendingDownloads = pendingDownloads.filter(d => d.id !== downloadId);
                        }
                    } catch (copyError) {
                        // Silent error handling
                    }
                }
            });
            
            // Navigate to ETQ
            const URL = 'https://nvidia.etq.com/prod/rel/#/app/system/module/VACATION2/view/SUFA_COMPANY_DOCUMENTS_P';
            await page.goto(URL);
            await page.waitForTimeout(5000);
            
            // Read the CSV file to get serial numbers
            let allSerialNumbers = [];
            try {
                const csvFile = config[`login_${mode}`].csv_file || 'newbook1.csv';
                const csvContent = fs.readFileSync(csvFile, 'utf-8');
                const lines = csvContent.split('\n').filter(line => line.trim());
                
                for (const line of lines) {
                    const serialNumber = line.trim();
                    if (serialNumber && serialNumber.length > 0) {
                        allSerialNumbers.push(serialNumber);
                    }
                }
            } catch (csvError) {
                allSerialNumbers = ["1653923071994"]; // Fallback
            }
            
            // Manual pause to allow user to zoom out
            console.log('Please manually zoom out to 75% to make the NVSN column visible.');
            console.log('Press Enter to continue...');
            
            await new Promise(resolve => {
                const rl = readline.createInterface({
                    input: process.stdin,
                    output: process.stdout
                });
                rl.question('', (answer) => {
                    rl.close();
                    // Small delay to ensure readline is fully closed
                    setTimeout(() => {
                        console.log('Continuing with script...');
                        resolve();
                    }, 100);
                });
            });
            
            // Perform login
            try {
                const atLoginPage = await isAtLoginPage(page);
                if (atLoginPage) {
                    const loginSuccess = await performLogin(page);
                    if (loginSuccess) {
                        await page.goto(URL, { waitUntil: 'networkidle' });
                        await page.waitForTimeout(3000);
                    }
                }
            } catch (error) {
                // Silent error handling
            }
            
            // Get unprocessed serial numbers
            let serialNumbers = getUnprocessedSerialNumbers(allSerialNumbers);
            
            if (serialNumbers.length === 0) {
                serialNumbers = [...allSerialNumbers];
            }
            
            console.log(`Starting with ${serialNumbers.length} serial numbers`);
            
            // Process serial numbers
            let currentIndex = 0;
            let consecutiveFailures = 0;
            const maxConsecutiveFailures = 3;
            
            while (true) {
                // Check if page is in a usable state before processing
                if (!(await isPageReady(page))) {
                    const recoverySuccess = await recoverPage(page);
                    if (recoverySuccess) {
                        consecutiveFailures = 0;
                    }
                }
                
                if (currentIndex >= serialNumbers.length) {
                    console.log('All serial numbers processed! Download completed.');
                    break;
                }
                
                const currentSerialNumber = serialNumbers[currentIndex];
                console.log(`${currentIndex + 1}/${serialNumbers.length} Processing ${currentSerialNumber}`);
                
                // Enter the serial number
                const entered = await enterSerialNumber(page, currentSerialNumber);
                if (entered) {
                    // Wait for the table results to appear
                    await page.waitForTimeout(3000);
                    
                    // Look for text containing "SUFA-" which should be in every result row
                    let sufaElement = null;
                    let attempts = 0;
                    const maxAttempts = 5;
                    
                    while (!sufaElement && attempts < maxAttempts) {
                        attempts++;
                        
                        try {
                            sufaElement = await page.$('text=SUFA-');
                            if (sufaElement) {
                                break;
                            }
                            
                            sufaElement = await page.$('text=/SUFA-.*/');
                            if (sufaElement) {
                                break;
                            }
                            
                            if (attempts < maxAttempts) {
                                await page.waitForTimeout(2000);
                            }
                            
                        } catch (error) {
                            if (attempts < maxAttempts) {
                                await page.waitForTimeout(2000);
                            }
                        }
                    }
                    
                    if (sufaElement) {
                        let clickSuccess = false;
                        let clickAttempts = 0;
                        const maxClickAttempts = 3;
                        sufaNumber = await sufaElement.textContent();
                        sufaNumber = sufaNumber.trim();
                        console.log(`Found SUFA Number: ${sufaNumber}`);
                        const outputFile = path.join(logFolder, 'Serial_SUFA_Mapping.csv');
                        const row = `${sufaNumber},${currentSerialNumber}\n`;
                        
                        // If file doesn't exist, write header first
                        if (!fs.existsSync(outputFile)) {
                            fs.writeFileSync(outputFile, 'SUFANumber,SerialNumber\n');
                        }
                        fs.appendFileSync(outputFile, row);                        
                        while (!clickSuccess && clickAttempts < maxClickAttempts) {
                            clickAttempts++;
                            
                            try {
                                await sufaElement.click();
                                clickSuccess = true;
                            } catch (error) {
                                if (clickAttempts < maxClickAttempts) {
                                    await page.waitForTimeout(2000);
                                }
                            }
                        }
                        
                        if (clickSuccess) {
                            // Wait for navigation to complete
                            await page.waitForTimeout(3000);
                            
                            // Download attachments logic
                            try {
                                const attachmentTable = await page.$('app-attachment-table');
                                if (!attachmentTable) {
                                    // No attachments section found
                                } else {
                                    await page.waitForSelector('app-attachment-table', { timeout: 10000 });
                                    
                                    const downloadLinks = await page.$$('a[download="true"]');
                                    
                                    if (downloadLinks.length > 0) {
                                        // Download each file
                                        for (let i = 0; i < downloadLinks.length; i++) {
                                            try {
                                                const link = downloadLinks[i];
                                                await link.click();
                                                await page.waitForTimeout(1000);
                                            } catch (downloadError) {
                                                // Silent error handling
                                            }
                                        }
                                        
                                        // Wait for downloads to start and be tracked
                                        await page.waitForTimeout(3000);
                                        
                                        // Wait for all downloads to complete and move them
                                        await waitForDownloadsAndMove(currentSerialNumber, pendingDownloads, completedDownloads);
                                    }
                                }
                                
                                // Close the tab
                                try {
                                    const closeButton = await page.$('[id^="_ACTION--CLOSE-"]');
                                    if (closeButton) {
                                        await closeButton.click();
                                        
                                        // Handle confirmation modal
                                        try {
                                            await page.waitForTimeout(1000);
                                            await page.keyboard.press('Tab');
                                            await page.waitForTimeout(500);
                                            await page.keyboard.press('Enter');
                                        } catch (modalError) {
                                            // Silent error handling
                                        }
                                        
                                        // Navigate back to main ETQ page
                                        try {
                                            await page.waitForTimeout(2000);
                                            
                                            const mainURL = 'https://nvidia.etq.com/prod/rel/#/app/system/module/VACATION2/view/SUFA_COMPANY_DOCUMENTS_P';
                                            await page.goto(mainURL, { waitUntil: 'networkidle', timeout: 30000 });
                                            await page.waitForTimeout(3000);
                                            
                                            // Clear the NVSN filter field
                                            try {
                                                const filterInputs = await page.$$('.ag-floating-filter-input');
                                                if (filterInputs.length > 0) {
                                                    const nvsnField = filterInputs[filterInputs.length - 2];
                                                    await nvsnField.click();
                                                    await page.keyboard.press('Control+a');
                                                    await page.keyboard.press('Delete');
                                                    await nvsnField.fill('');
                                                }
                                            } catch (clearError) {
                                                // Silent error handling
                                            }
                                            
                                        } catch (navError) {
                                            try {
                                                const configURL = config.path || 'https://nvidia.etq.com/prod/rel/#/app/system/module/VACATION2/view/SUFA_COMPANY_DOCUMENTS_P';
                                                await page.goto(configURL, { waitUntil: 'networkidle', timeout: 30000 });
                                                await page.waitForTimeout(3000);
                                            } catch (altNavError) {
                                                // Silent error handling
                                            }
                                        }
                                    } else {
                                        // Try to navigate back even without closing
                                        try {
                                            const mainURL = 'https://nvidia.etq.com/prod/rel/#/app/system/module/VACATION2/view/SUFA_COMPANY_DOCUMENTS_P';
                                            await page.goto(mainURL, { waitUntil: 'networkidle', timeout: 30000 });
                                            await page.waitForTimeout(3000);
                                        } catch (navError) {
                                            // Silent error handling
                                        }
                                    }
                                } catch (closeError) {
                                    // Silent error handling
                                }
                                
                            } catch (attachmentError) {
                                // Silent error handling
                            }
                        }
                    }
                    
                } else {
                    consecutiveFailures++;
                    
                    if (consecutiveFailures >= maxConsecutiveFailures) {
                        const recoverySuccess = await recoverPage(page);
                        if (recoverySuccess) {
                            consecutiveFailures = 0;
                        } else {
                            consecutiveFailures = 0;
                        }
                    } else {
                        await page.waitForTimeout(5000);
                    }
                }
                
                // Move to next serial number
                currentIndex++;
                
                // Small delay between processing serial numbers
                await page.waitForTimeout(3000);
                
                // Periodic health check every 10 serial numbers
                if (currentIndex % 10 === 0 && currentIndex > 0) {
                    if (!(await isPageReady(page))) {
                        const recoverySuccess = await recoverPage(page);
                        // Continue regardless of recovery success
                    }
                }
            }
            
        } catch (error) {
            console.error(`Error: ${error.message}`);
        }
        
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }

    analyzeLogs();
}

// Run the script
if (require.main === module) {
    try {
        loadConfig();
        main();
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

module.exports = { main };
