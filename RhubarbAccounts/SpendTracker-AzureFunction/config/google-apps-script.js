/**
 * Google Apps Script for SpendTracker - Push Notifications
 * 
 * This script should be added to your Google Sheet to enable real-time sync
 * when the sheet is modified.
 * 
 * Setup Instructions:
 * 1. Open your Google Sheet
 * 2. Go to Extensions > Apps Script
 * 3. Replace the default code with this script
 * 4. Update the AZURE_FUNCTION_URL and SECRET_KEY constants below
 * 5. Save and authorize the script
 * 6. The script will automatically create triggers for sheet changes
 */

// Configuration - UPDATE THESE VALUES
const AZURE_FUNCTION_URL = 'https://your-function-app.azurewebsites.net/api/sync_webhook';
const SECRET_KEY = 'your-secret-key-here';  // Must match SYNC_SECRET_KEY in Azure Functions

// Advanced configuration
const DEBOUNCE_DELAY_MS = 2000;  // Wait 2 seconds after last change before syncing
const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;

// Global variables for debouncing
let syncTimeoutId = null;
let lastChangeTime = null;

/**
 * Initialize the script and set up triggers
 * Run this once after pasting the script
 */
function initializeSpendTracker() {
  console.log('Initializing SpendTracker...');
  
  // Remove existing triggers to avoid duplicates
  removeExistingTriggers();
  
  // Create new triggers
  createTriggers();
  
  // Test the webhook connection
  testWebhookConnection();
  
  console.log('SpendTracker initialization complete!');
}

/**
 * Create necessary triggers for the sheet
 */
function createTriggers() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  
  // Trigger on edit (when cells are modified)
  ScriptApp.newTrigger('onSheetEdit')
    .forSpreadsheet(sheet)
    .onEdit()
    .create();
  
  // Trigger on change (when structure changes)
  ScriptApp.newTrigger('onSheetChange')
    .forSpreadsheet(sheet)
    .onChange()
    .create();
  
  console.log('Triggers created successfully');
}

/**
 * Remove existing triggers to avoid duplicates
 */
function removeExistingTriggers() {
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'onSheetEdit' || 
        trigger.getHandlerFunction() === 'onSheetChange') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  console.log('Existing triggers removed');
}

/**
 * Handle sheet edit events (cell value changes)
 */
function onSheetEdit(e) {
  console.log('Sheet edit detected:', e);
  
  // Update last change time
  lastChangeTime = new Date();
  
  // Clear existing timeout and set new one (debouncing)
  if (syncTimeoutId) {
    Utilities.clearTimeout(syncTimeoutId);
  }
  
  syncTimeoutId = Utilities.setTimeout(() => {
    triggerSync('edit', {
      range: e.range ? e.range.getA1Notation() : 'unknown',
      oldValue: e.oldValue || null,
      value: e.value || null,
      user: e.user ? e.user.getEmail() : 'unknown'
    });
  }, DEBOUNCE_DELAY_MS);
}

/**
 * Handle sheet change events (structure changes)
 */
function onSheetChange(e) {
  console.log('Sheet change detected:', e);
  
  // Update last change time
  lastChangeTime = new Date();
  
  // Clear existing timeout and set new one (debouncing)
  if (syncTimeoutId) {
    Utilities.clearTimeout(syncTimeoutId);
  }
  
  syncTimeoutId = Utilities.setTimeout(() => {
    triggerSync('change', {
      changeType: e.changeType || 'unknown'
    });
  }, DEBOUNCE_DELAY_MS);
}

/**
 * Trigger sync with Azure Functions
 */
function triggerSync(eventType, eventData = {}) {
  console.log(`Triggering sync for ${eventType}...`);
  
  const payload = {
    timestamp: new Date().toISOString(),
    eventType: eventType,
    eventData: eventData,
    sheetId: SpreadsheetApp.getActiveSpreadsheet().getId(),
    sheetName: SpreadsheetApp.getActiveSheet().getName()
  };
  
  // Attempt sync with retries
  let success = false;
  for (let attempt = 1; attempt <= MAX_RETRIES && !success; attempt++) {
    try {
      console.log(`Sync attempt ${attempt}/${MAX_RETRIES}`);
      
      const response = UrlFetchApp.fetch(AZURE_FUNCTION_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Sync-Secret': SECRET_KEY
        },
        payload: JSON.stringify(payload),
        muteHttpExceptions: true  // Don't throw on HTTP errors
      });
      
      const responseCode = response.getResponseCode();
      const responseText = response.getContentText();
      
      if (responseCode >= 200 && responseCode < 300) {
        console.log('Sync successful:', responseText);
        success = true;
        
        // Log success to sheet properties (optional)
        logSyncResult(true, `Sync successful at ${new Date().toISOString()}`);
        
      } else {
        console.error(`Sync failed with HTTP ${responseCode}:`, responseText);
        
        if (attempt === MAX_RETRIES) {
          logSyncResult(false, `Sync failed after ${MAX_RETRIES} attempts. Last error: HTTP ${responseCode}`);
        }
      }
      
    } catch (error) {
      console.error(`Sync attempt ${attempt} failed:`, error.toString());
      
      if (attempt === MAX_RETRIES) {
        logSyncResult(false, `Sync failed after ${MAX_RETRIES} attempts. Last error: ${error.toString()}`);
      } else {
        // Wait before retry
        Utilities.sleep(RETRY_DELAY_MS * attempt);
      }
    }
  }
}

/**
 * Test webhook connection
 */
function testWebhookConnection() {
  console.log('Testing webhook connection...');
  
  try {
    const testPayload = {
      timestamp: new Date().toISOString(),
      eventType: 'test',
      eventData: { message: 'Test connection from Google Apps Script' },
      sheetId: SpreadsheetApp.getActiveSpreadsheet().getId(),
      sheetName: 'Connection Test'
    };
    
    const response = UrlFetchApp.fetch(AZURE_FUNCTION_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sync-Secret': SECRET_KEY
      },
      payload: JSON.stringify(testPayload),
      muteHttpExceptions: true
    });
    
    const responseCode = response.getResponseCode();
    const responseText = response.getContentText();
    
    if (responseCode >= 200 && responseCode < 300) {
      console.log('✅ Webhook connection test successful!');
      Browser.msgBox('SpendTracker Setup', 
        '✅ Webhook connection test successful! Your sheet is now connected to Azure Functions.', 
        Browser.Buttons.OK);
    } else {
      console.error('❌ Webhook connection test failed:', responseCode, responseText);
      Browser.msgBox('SpendTracker Setup', 
        `❌ Webhook connection test failed!\n\nHTTP ${responseCode}: ${responseText}\n\nPlease check your AZURE_FUNCTION_URL and SECRET_KEY.`, 
        Browser.Buttons.OK);
    }
    
  } catch (error) {
    console.error('❌ Webhook connection test error:', error.toString());
    Browser.msgBox('SpendTracker Setup', 
      `❌ Webhook connection test error!\n\n${error.toString()}\n\nPlease check your configuration.`, 
      Browser.Buttons.OK);
  }
}

/**
 * Manual sync trigger for testing
 */
function manualSync() {
  console.log('Manual sync triggered');
  triggerSync('manual', { 
    message: 'Manual sync triggered by user',
    trigger_time: new Date().toISOString()
  });
}

/**
 * Log sync results to sheet properties
 */
function logSyncResult(success, message) {
  try {
    const properties = PropertiesService.getDocumentProperties();
    const timestamp = new Date().toISOString();
    
    properties.setProperties({
      'lastSyncSuccess': success.toString(),
      'lastSyncMessage': message,
      'lastSyncTime': timestamp
    });
    
  } catch (error) {
    console.error('Error logging sync result:', error.toString());
  }
}

/**
 * Get last sync status
 */
function getLastSyncStatus() {
  try {
    const properties = PropertiesService.getDocumentProperties();
    const status = {
      success: properties.getProperty('lastSyncSuccess') === 'true',
      message: properties.getProperty('lastSyncMessage') || 'No sync attempts yet',
      time: properties.getProperty('lastSyncTime') || 'Never'
    };
    
    console.log('Last sync status:', status);
    return status;
  } catch (error) {
    console.error('Error getting sync status:', error.toString());
    return { success: false, message: 'Error retrieving status', time: 'Unknown' };
  }
}

/**
 * Show configuration help
 */
function showConfigurationHelp() {
  const helpText = `
SpendTracker Configuration Help

1. Update Configuration Constants:
   - AZURE_FUNCTION_URL: Your Azure Function webhook URL
   - SECRET_KEY: Must match the SYNC_SECRET_KEY in your Azure Functions

2. Run Setup:
   - Execute 'initializeSpendTracker()' function once

3. Test Connection:
   - Execute 'testWebhookConnection()' to verify setup

4. Manual Sync:
   - Execute 'manualSync()' to trigger immediate sync

5. Check Status:
   - Execute 'getLastSyncStatus()' to see last sync result

Current Configuration:
- URL: ${AZURE_FUNCTION_URL}
- Secret Key: ${SECRET_KEY ? '[CONFIGURED]' : '[NOT SET]'}
`;

  console.log(helpText);
  Browser.msgBox('SpendTracker Configuration', helpText, Browser.Buttons.OK);
}