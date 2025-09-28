import os
import logging
from typing import List, Dict, Any, Optional
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import json

logger = logging.getLogger(__name__)

class GoogleSheetsClient:
    def __init__(self, credentials_path: str, sheet_id: str):
        """
        Initialize Google Sheets client
        
        Args:
            credentials_path: Path to service account JSON file
            sheet_id: Google Sheet ID from the URL
        """
        self.sheet_id = sheet_id
        self.service = None
        self._initialize_service(credentials_path)
    
    def _initialize_service(self, credentials_path: str):
        """Initialize Google Sheets service with credentials"""
        try:
            if credentials_path and os.path.exists(credentials_path):
                # Use service account credentials
                credentials = Credentials.from_service_account_file(
                    credentials_path,
                    scopes=['https://www.googleapis.com/auth/spreadsheets.readonly']
                )
            else:
                # Try to get credentials from environment variable
                creds_json = os.getenv('GOOGLE_SHEETS_CREDENTIALS_JSON')
                if creds_json:
                    credentials_info = json.loads(creds_json)
                    credentials = Credentials.from_service_account_info(
                        credentials_info,
                        scopes=['https://www.googleapis.com/auth/spreadsheets.readonly']
                    )
                else:
                    raise ValueError("No Google Sheets credentials found")
            
            self.service = build('sheets', 'v4', credentials=credentials)
            logger.info("Google Sheets service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Google Sheets service: {str(e)}")
            raise
    
    def get_sheet_data(self, range_name: str = "A:Z") -> List[List[str]]:
        """
        Get data from the specified sheet range
        
        Args:
            range_name: Sheet range (e.g., "Sheet1!A:Z" or "A:Z")
            
        Returns:
            List of rows, where each row is a list of cell values
        """
        try:
            result = self.service.spreadsheets().values().get(
                spreadsheetId=self.sheet_id,
                range=range_name
            ).execute()
            
            values = result.get('values', [])
            logger.info(f"Retrieved {len(values)} rows from Google Sheets")
            return values
            
        except HttpError as e:
            logger.error(f"HTTP error getting sheet data: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error getting sheet data: {str(e)}")
            raise
    
    def get_sheet_metadata(self) -> Dict[str, Any]:
        """Get sheet metadata including last modified time"""
        try:
            result = self.service.spreadsheets().get(
                spreadsheetId=self.sheet_id,
                fields="properties"
            ).execute()
            
            return result.get('properties', {})
            
        except Exception as e:
            logger.error(f"Error getting sheet metadata: {str(e)}")
            raise
    
    def parse_spend_data(self, raw_data: List[List[str]]) -> List[Dict[str, Any]]:
        """
        Parse raw sheet data into structured spend records
        
        Expected columns: Date, Spend Type, Spend Item, Ingoing, Outgoing, Balance
        """
        if not raw_data or len(raw_data) < 2:
            logger.warning("No data or insufficient data in sheet")
            return []
        
        # Assume first row contains headers
        headers = raw_data[0]
        logger.info(f"Sheet headers: {headers}")
        
        # Map common header variations to standard names
        header_mapping = {
            'date': ['date', 'Date', 'DATE'],
            'spend_type': ['spend type', 'Spend Type', 'SPEND TYPE', 'type', 'Type'],
            'spend_item': ['spend item', 'Spend Item', 'SPEND ITEM', 'item', 'Item', 'description', 'Description'],
            'ingoing': ['ingoing', 'Ingoing', 'INGOING', 'income', 'Income', 'credit', 'Credit'],
            'outgoing': ['outgoing', 'Outgoing', 'OUTGOING', 'expense', 'Expense', 'debit', 'Debit'],
            'balance': ['balance', 'Balance', 'BALANCE']
        }
        
        # Find column indices
        column_indices = {}
        for standard_name, variations in header_mapping.items():
            for i, header in enumerate(headers):
                if header.strip() in variations:
                    column_indices[standard_name] = i
                    break
        
        logger.info(f"Mapped columns: {column_indices}")
        
        # Parse data rows
        spend_records = []
        for row_idx, row in enumerate(raw_data[1:], start=2):  # Skip header row
            try:
                if not any(cell.strip() for cell in row if cell):  # Skip empty rows
                    continue
                
                record = {
                    'row_number': row_idx,
                    'date': self._get_cell_value(row, column_indices.get('date')),
                    'spend_type': self._get_cell_value(row, column_indices.get('spend_type')),
                    'spend_item': self._get_cell_value(row, column_indices.get('spend_item')),
                    'ingoing': self._parse_amount(self._get_cell_value(row, column_indices.get('ingoing'))),
                    'outgoing': self._parse_amount(self._get_cell_value(row, column_indices.get('outgoing'))),
                    'balance': self._parse_amount(self._get_cell_value(row, column_indices.get('balance')))
                }
                
                # Only add records with at least a date
                if record['date']:
                    spend_records.append(record)
                    
            except Exception as e:
                logger.warning(f"Error parsing row {row_idx}: {str(e)}")
                continue
        
        logger.info(f"Parsed {len(spend_records)} spend records")
        return spend_records
    
    def _get_cell_value(self, row: List[str], column_index: Optional[int]) -> str:
        """Safely get cell value by column index"""
        if column_index is None or column_index >= len(row):
            return ""
        return row[column_index].strip()
    
    def _parse_amount(self, value: str) -> Optional[float]:
        """Parse monetary amount from string"""
        if not value:
            return None
        
        try:
            # Remove currency symbols and spaces
            cleaned = value.replace('£', '').replace('$', '').replace(',', '').strip()
            if cleaned:
                return float(cleaned)
        except ValueError:
            pass
        
        return None