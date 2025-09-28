import logging
import json
import os
import azure.functions as func
from typing import Dict, Any

# Import our shared modules
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from shared.sync_service import SpendSyncService

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP triggered function for webhook-based Google Sheets sync
    This function is called by Google Apps Script when the sheet is modified
    """
    logging.info('HTTP trigger function (sync_webhook) processed a request.')
    
    try:
        # Validate secret key for security
        secret_key = req.headers.get('X-Sync-Secret') or req.params.get('secret')
        expected_secret = os.environ.get('SYNC_SECRET_KEY')
        
        if not secret_key or secret_key != expected_secret:
            logging.warning('Unauthorized webhook request - invalid or missing secret key')
            return func.HttpResponse(
                json.dumps({'error': 'Unauthorized'}),
                status_code=401,
                mimetype='application/json'
            )
        
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
            return func.HttpResponse(
                json.dumps({'error': error_msg}),
                status_code=500,
                mimetype='application/json'
            )
        
        # Parse request body for additional context (optional)
        webhook_data = {}
        try:
            if req.get_body():
                webhook_data = req.get_json()
                logging.info(f'Webhook data received: {webhook_data}')
        except ValueError:
            logging.info('No JSON data in webhook request body')
        
        # Initialize sync service
        sync_service = SpendSyncService(
            google_credentials_path=google_credentials_path,
            sheet_id=sheet_id,
            azure_sql_connection_string=azure_sql_connection
        )
        
        # Perform sync
        logging.info('Starting webhook-triggered sync...')
        sync_result = sync_service.sync_data(sync_type='webhook')
        
        # Prepare response
        response_data = {
            'status': 'success' if sync_result['success'] else 'error',
            'sync_result': sync_result,
            'webhook_data': webhook_data,
            'timestamp': sync_result.get('sync_id', 'unknown')
        }
        
        status_code = 200 if sync_result['success'] else 500
        
        logging.info(f'Webhook sync completed. Status: {status_code}')
        
        return func.HttpResponse(
            json.dumps(response_data, default=str),
            status_code=status_code,
            mimetype='application/json'
        )
        
    except Exception as e:
        error_msg = f"Webhook sync failed: {str(e)}"
        logging.error(error_msg, exc_info=True)
        
        return func.HttpResponse(
            json.dumps({
                'status': 'error',
                'error': error_msg,
                'sync_result': {
                    'success': False,
                    'error': str(e)
                }
            }),
            status_code=500,
            mimetype='application/json'
        )