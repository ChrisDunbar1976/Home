import logging
import json
import os
import azure.functions as func

# Import our shared modules
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from shared.sync_service import SpendSyncService

def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP triggered function to get sync status and recent activity
    """
    logging.info('HTTP trigger function (sync_status) processed a request.')
    
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
            return func.HttpResponse(
                json.dumps({'error': error_msg}),
                status_code=500,
                mimetype='application/json'
            )
        
        # Initialize sync service
        sync_service = SpendSyncService(
            google_credentials_path=google_credentials_path,
            sheet_id=sheet_id,
            azure_sql_connection_string=azure_sql_connection
        )
        
        # Get sync status
        status = sync_service.get_sync_status()
        
        # Get validation status if requested
        validate_param = req.params.get('validate', '').lower()
        if validate_param in ['true', '1', 'yes']:
            validation = sync_service.validate_configuration()
            status['validation'] = validation
        
        return func.HttpResponse(
            json.dumps(status, default=str),
            status_code=200,
            mimetype='application/json'
        )
        
    except Exception as e:
        error_msg = f"Status check failed: {str(e)}"
        logging.error(error_msg, exc_info=True)
        
        return func.HttpResponse(
            json.dumps({
                'error': error_msg,
                'success': False
            }),
            status_code=500,
            mimetype='application/json'
        )