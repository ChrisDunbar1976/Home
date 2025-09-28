import os
import logging
import pyodbc
from typing import List, Dict, Any, Optional
from datetime import datetime
import json

logger = logging.getLogger(__name__)

class AzureSQLClient:
    def __init__(self, connection_string: str):
        """
        Initialize Azure SQL client
        
        Args:
            connection_string: Azure SQL Database connection string
        """
        self.connection_string = connection_string
        self.connection = None
    
    def connect(self):
        """Establish database connection"""
        try:
            self.connection = pyodbc.connect(self.connection_string)
            logger.info("Connected to Azure SQL Database")
        except Exception as e:
            logger.error(f"Failed to connect to Azure SQL Database: {str(e)}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
            logger.info("Disconnected from Azure SQL Database")
    
    def __enter__(self):
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.disconnect()
    
    def create_tables_if_not_exist(self):
        """Create necessary tables if they don't exist"""
        create_spend_table = """
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='spend_records' AND xtype='U')
        CREATE TABLE spend_records (
            id BIGINT IDENTITY(1,1) PRIMARY KEY,
            sheet_row_number INT,
            date_recorded DATE,
            spend_type NVARCHAR(100),
            spend_item NVARCHAR(500),
            ingoing DECIMAL(10,2),
            outgoing DECIMAL(10,2),
            balance DECIMAL(10,2),
            created_at DATETIME2 DEFAULT GETDATE(),
            updated_at DATETIME2 DEFAULT GETDATE(),
            sheet_sync_id NVARCHAR(100),
            UNIQUE(sheet_row_number, sheet_sync_id)
        )
        """
        
        create_sync_log_table = """
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='sync_log' AND xtype='U')
        CREATE TABLE sync_log (
            id BIGINT IDENTITY(1,1) PRIMARY KEY,
            sync_timestamp DATETIME2 DEFAULT GETDATE(),
            sync_type NVARCHAR(50),  -- 'timer' or 'webhook'
            records_processed INT,
            records_inserted INT,
            records_updated INT,
            success BIT,
            error_message NVARCHAR(MAX),
            execution_time_ms INT
        )
        """
        
        try:
            cursor = self.connection.cursor()
            cursor.execute(create_spend_table)
            cursor.execute(create_sync_log_table)
            self.connection.commit()
            logger.info("Database tables created/verified successfully")
        except Exception as e:
            logger.error(f"Error creating tables: {str(e)}")
            raise
    
    def get_last_sync_info(self, sync_type: str = None) -> Optional[Dict[str, Any]]:
        """Get information about the last successful sync"""
        try:
            cursor = self.connection.cursor()
            
            if sync_type:
                query = """
                SELECT TOP 1 sync_timestamp, records_processed, records_inserted, records_updated
                FROM sync_log 
                WHERE success = 1 AND sync_type = ?
                ORDER BY sync_timestamp DESC
                """
                cursor.execute(query, sync_type)
            else:
                query = """
                SELECT TOP 1 sync_timestamp, records_processed, records_inserted, records_updated
                FROM sync_log 
                WHERE success = 1
                ORDER BY sync_timestamp DESC
                """
                cursor.execute(query)
            
            row = cursor.fetchone()
            if row:
                return {
                    'last_sync': row[0],
                    'records_processed': row[1],
                    'records_inserted': row[2],
                    'records_updated': row[3]
                }
            return None
            
        except Exception as e:
            logger.error(f"Error getting last sync info: {str(e)}")
            return None
    
    def upsert_spend_records(self, records: List[Dict[str, Any]], sheet_sync_id: str) -> Dict[str, int]:
        """
        Insert or update spend records
        
        Args:
            records: List of spend record dictionaries
            sheet_sync_id: Unique identifier for this sync session
            
        Returns:
            Dictionary with counts of inserted and updated records
        """
        if not records:
            return {'inserted': 0, 'updated': 0}
        
        inserted_count = 0
        updated_count = 0
        
        try:
            cursor = self.connection.cursor()
            
            for record in records:
                # Check if record exists based on row number and sync ID
                check_query = """
                SELECT id FROM spend_records 
                WHERE sheet_row_number = ? AND sheet_sync_id = ?
                """
                cursor.execute(check_query, record['row_number'], sheet_sync_id)
                existing = cursor.fetchone()
                
                if existing:
                    # Update existing record
                    update_query = """
                    UPDATE spend_records 
                    SET date_recorded = ?, spend_type = ?, spend_item = ?, 
                        ingoing = ?, outgoing = ?, balance = ?, updated_at = GETDATE()
                    WHERE id = ?
                    """
                    cursor.execute(update_query, 
                                 self._parse_date(record['date']),
                                 record['spend_type'],
                                 record['spend_item'],
                                 record['ingoing'],
                                 record['outgoing'],
                                 record['balance'],
                                 existing[0])
                    updated_count += 1
                else:
                    # Insert new record
                    insert_query = """
                    INSERT INTO spend_records 
                    (sheet_row_number, date_recorded, spend_type, spend_item, 
                     ingoing, outgoing, balance, sheet_sync_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """
                    cursor.execute(insert_query,
                                 record['row_number'],
                                 self._parse_date(record['date']),
                                 record['spend_type'],
                                 record['spend_item'],
                                 record['ingoing'],
                                 record['outgoing'],
                                 record['balance'],
                                 sheet_sync_id)
                    inserted_count += 1
            
            self.connection.commit()
            logger.info(f"Upserted {len(records)} records: {inserted_count} inserted, {updated_count} updated")
            
            return {'inserted': inserted_count, 'updated': updated_count}
            
        except Exception as e:
            self.connection.rollback()
            logger.error(f"Error upserting spend records: {str(e)}")
            raise
    
    def log_sync_attempt(self, sync_type: str, records_processed: int, 
                        records_inserted: int, records_updated: int, 
                        success: bool, error_message: str = None, 
                        execution_time_ms: int = 0):
        """Log sync attempt to sync_log table"""
        try:
            cursor = self.connection.cursor()
            
            insert_query = """
            INSERT INTO sync_log 
            (sync_type, records_processed, records_inserted, records_updated, 
             success, error_message, execution_time_ms)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """
            
            cursor.execute(insert_query,
                         sync_type,
                         records_processed,
                         records_inserted,
                         records_updated,
                         success,
                         error_message,
                         execution_time_ms)
            
            self.connection.commit()
            logger.info(f"Logged sync attempt: {sync_type}, Success: {success}")
            
        except Exception as e:
            logger.error(f"Error logging sync attempt: {str(e)}")
    
    def get_recent_records(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent spend records for verification"""
        try:
            cursor = self.connection.cursor()
            
            query = """
            SELECT TOP (?) id, sheet_row_number, date_recorded, spend_type, 
                   spend_item, ingoing, outgoing, balance, created_at, updated_at
            FROM spend_records 
            ORDER BY updated_at DESC
            """
            
            cursor.execute(query, limit)
            rows = cursor.fetchall()
            
            records = []
            for row in rows:
                records.append({
                    'id': row[0],
                    'sheet_row_number': row[1],
                    'date_recorded': row[2],
                    'spend_type': row[3],
                    'spend_item': row[4],
                    'ingoing': float(row[5]) if row[5] else None,
                    'outgoing': float(row[6]) if row[6] else None,
                    'balance': float(row[7]) if row[7] else None,
                    'created_at': row[8],
                    'updated_at': row[9]
                })
            
            return records
            
        except Exception as e:
            logger.error(f"Error getting recent records: {str(e)}")
            return []
    
    def _parse_date(self, date_str: str) -> Optional[datetime]:
        """Parse date string to datetime object"""
        if not date_str:
            return None
        
        # Common date formats
        date_formats = [
            '%Y-%m-%d',     # 2024-01-15
            '%d/%m/%Y',     # 15/01/2024
            '%m/%d/%Y',     # 01/15/2024
            '%d-%m-%Y',     # 15-01-2024
            '%d.%m.%Y',     # 15.01.2024
        ]
        
        for fmt in date_formats:
            try:
                return datetime.strptime(date_str.strip(), fmt)
            except ValueError:
                continue
        
        logger.warning(f"Could not parse date: {date_str}")
        return None