import logging
import os
import azure.functions as func
from datetime import datetime

# Import our shared modules
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from shared.sync_service import SpendSyncService

def main(mytimer: func.TimerRequest) -> None:
    """
    Timer triggered function for scheduled Google Sheets sync
    Runs every 15 minutes as backup to webhook sync
    """
    utc_timestamp = datetime.utcnow().replace(
        tzinfo=None
    ).isoformat()
    
    logging.info(f'Timer trigger function (sync_timer) ran at {utc_timestamp}')
    
    if mytimer.past_due:
        logging.info('Timer function is running late!')
    
    try:
        # Get configuration from environment variables
        google_credentials_path = os.environ.get('GOOGLE_SHEETS_CREDENTIALS_PATH')
        sheet_id = os.environ.get('GOOGLE_SHEET_ID')
        azure_sql_connection = os.environ.get('AZURE_SQL_CONNECTION_STRING')
        
        # Validate configuration
        if not all([sheet_id, azure_sql_connection]):
            missing = []
            if not sheet_id:
                missing.append('GOOGLE_SHEET_ID')
            if not azure_sql_connection:
                missing.append('AZURE_SQL_CONNECTION_STRING')
            
            error_msg = f"Missing required environment variables: {', '.join(missing)}"
            logging.error(error_msg)
            return
        
        # Initialize sync service
        sync_service = SpendSyncService(
            google_credentials_path=google_credentials_path,
            sheet_id=sheet_id,
            azure_sql_connection_string=azure_sql_connection
        )
        
        # Check if recent webhook sync has occurred (avoid duplicate work)
        status = sync_service.get_sync_status()
        last_sync = status.get('last_sync')
        
        # Only proceed if no recent sync (within last 10 minutes) or if it's been more than an hour
        should_sync = True
        if last_sync and last_sync.get('last_sync'):
            time_since_last = datetime.utcnow() - last_sync['last_sync']
            minutes_since_last = time_since_last.total_seconds() / 60
            
            if minutes_since_last < 10:
                logging.info(f'Recent sync found ({minutes_since_last:.1f} minutes ago), skipping timer sync')
                should_sync = False
            else:
                logging.info(f'Last sync was {minutes_since_last:.1f} minutes ago, proceeding with timer sync')
        
        if should_sync:
            # Perform sync
            logging.info('Starting timer-triggered sync...')
            sync_result = sync_service.sync_data(sync_type='timer')
            
            if sync_result['success']:
                logging.info(f"Timer sync completed successfully: {sync_result['records_processed']} records processed, "
                           f"{sync_result['records_inserted']} inserted, {sync_result['records_updated']} updated")
            else:
                logging.error(f"Timer sync failed: {sync_result.get('error', 'Unknown error')}")
        else:
            logging.info('Timer sync skipped due to recent webhook sync')
        
    except Exception as e:
        error_msg = f"Timer sync failed: {str(e)}"
        logging.error(error_msg, exc_info=True)