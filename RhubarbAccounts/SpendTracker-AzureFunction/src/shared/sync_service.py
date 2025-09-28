import os
import logging
from typing import Dict, Any, List
from datetime import datetime
import hashlib

from .google_sheets_client import GoogleSheetsClient
from .azure_sql_client import AzureSQLClient

logger = logging.getLogger(__name__)

class SpendSyncService:
    def __init__(self, google_credentials_path: str, sheet_id: str, 
                 azure_sql_connection_string: str):
        """
        Initialize the sync service
        
        Args:
            google_credentials_path: Path to Google service account credentials
            sheet_id: Google Sheet ID
            azure_sql_connection_string: Azure SQL connection string
        """
        self.google_client = GoogleSheetsClient(google_credentials_path, sheet_id)
        self.azure_sql_connection_string = azure_sql_connection_string
        self.sheet_id = sheet_id
    
    def sync_data(self, sync_type: str = "manual") -> Dict[str, Any]:
        """
        Main sync function that pulls data from Google Sheets and updates Azure SQL
        
        Args:
            sync_type: Type of sync ('timer', 'webhook', 'manual')
            
        Returns:
            Dictionary containing sync results
        """
        start_time = datetime.now()
        sync_id = self._generate_sync_id()
        
        try:
            logger.info(f"Starting {sync_type} sync with ID: {sync_id}")
            
            # Get data from Google Sheets
            raw_data = self.google_client.get_sheet_data()
            spend_records = self.google_client.parse_spend_data(raw_data)
            
            if not spend_records:
                logger.warning("No spend records found in Google Sheets")
                return {
                    'success': True,
                    'sync_id': sync_id,
                    'sync_type': sync_type,
                    'records_processed': 0,
                    'records_inserted': 0,
                    'records_updated': 0,
                    'execution_time_ms': self._get_execution_time_ms(start_time),
                    'message': 'No records to sync'
                }
            
            # Sync with Azure SQL Database
            with AzureSQLClient(self.azure_sql_connection_string) as sql_client:
                # Ensure tables exist
                sql_client.create_tables_if_not_exist()
                
                # Upsert records
                upsert_results = sql_client.upsert_spend_records(spend_records, sync_id)
                
                execution_time_ms = self._get_execution_time_ms(start_time)
                
                # Log successful sync
                sql_client.log_sync_attempt(
                    sync_type=sync_type,
                    records_processed=len(spend_records),
                    records_inserted=upsert_results['inserted'],
                    records_updated=upsert_results['updated'],
                    success=True,
                    execution_time_ms=execution_time_ms
                )
                
                result = {
                    'success': True,
                    'sync_id': sync_id,
                    'sync_type': sync_type,
                    'records_processed': len(spend_records),
                    'records_inserted': upsert_results['inserted'],
                    'records_updated': upsert_results['updated'],
                    'execution_time_ms': execution_time_ms,
                    'message': f'Successfully synced {len(spend_records)} records'
                }
                
                logger.info(f"Sync completed successfully: {result}")
                return result
                
        except Exception as e:
            execution_time_ms = self._get_execution_time_ms(start_time)
            error_message = str(e)
            
            logger.error(f"Sync failed: {error_message}")
            
            # Try to log failed sync attempt
            try:
                with AzureSQLClient(self.azure_sql_connection_string) as sql_client:
                    sql_client.log_sync_attempt(
                        sync_type=sync_type,
                        records_processed=0,
                        records_inserted=0,
                        records_updated=0,
                        success=False,
                        error_message=error_message,
                        execution_time_ms=execution_time_ms
                    )
            except Exception as log_error:
                logger.error(f"Failed to log sync error: {str(log_error)}")
            
            return {
                'success': False,
                'sync_id': sync_id,
                'sync_type': sync_type,
                'records_processed': 0,
                'records_inserted': 0,
                'records_updated': 0,
                'execution_time_ms': execution_time_ms,
                'error': error_message
            }
    
    def get_sync_status(self) -> Dict[str, Any]:
        """Get current sync status and recent activity"""
        try:
            with AzureSQLClient(self.azure_sql_connection_string) as sql_client:
                last_sync = sql_client.get_last_sync_info()
                recent_records = sql_client.get_recent_records(5)
                
                return {
                    'last_sync': last_sync,
                    'recent_records': recent_records,
                    'sheet_id': self.sheet_id
                }
                
        except Exception as e:
            logger.error(f"Error getting sync status: {str(e)}")
            return {
                'error': str(e),
                'sheet_id': self.sheet_id
            }
    
    def validate_configuration(self) -> Dict[str, Any]:
        """Validate that all required services are accessible"""
        validation_results = {
            'google_sheets': False,
            'azure_sql': False,
            'overall': False,
            'errors': []
        }
        
        # Test Google Sheets connection
        try:
            metadata = self.google_client.get_sheet_metadata()
            if metadata:
                validation_results['google_sheets'] = True
                logger.info("Google Sheets connection validated successfully")
        except Exception as e:
            validation_results['errors'].append(f"Google Sheets error: {str(e)}")
            logger.error(f"Google Sheets validation failed: {str(e)}")
        
        # Test Azure SQL connection
        try:
            with AzureSQLClient(self.azure_sql_connection_string) as sql_client:
                sql_client.create_tables_if_not_exist()
                validation_results['azure_sql'] = True
                logger.info("Azure SQL connection validated successfully")
        except Exception as e:
            validation_results['errors'].append(f"Azure SQL error: {str(e)}")
            logger.error(f"Azure SQL validation failed: {str(e)}")
        
        validation_results['overall'] = (
            validation_results['google_sheets'] and 
            validation_results['azure_sql']
        )
        
        return validation_results
    
    def _generate_sync_id(self) -> str:
        """Generate unique sync ID"""
        timestamp = datetime.now().isoformat()
        hash_input = f"{self.sheet_id}_{timestamp}"
        return hashlib.md5(hash_input.encode()).hexdigest()[:12]
    
    def _get_execution_time_ms(self, start_time: datetime) -> int:
        """Calculate execution time in milliseconds"""
        return int((datetime.now() - start_time).total_seconds() * 1000)