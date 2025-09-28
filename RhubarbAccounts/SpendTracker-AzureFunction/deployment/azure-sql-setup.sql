-- SpendTracker Azure SQL Database Setup Script
-- Run this script on your Azure SQL Database after creation

-- Create database user for the Function App (if using SQL authentication)
-- Replace 'spendtracker_user' and 'YourSecurePassword123!' with your chosen credentials
-- CREATE LOGIN spendtracker_user WITH PASSWORD = 'YourSecurePassword123!';
-- CREATE USER spendtracker_user FOR LOGIN spendtracker_user;

-- Grant necessary permissions
-- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO spendtracker_user;

-- Create tables (these will be created automatically by the Function App, but you can create them manually if preferred)
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
    
    -- Ensure unique records per sheet sync
    CONSTRAINT UQ_spend_records_row_sync UNIQUE(sheet_row_number, sheet_sync_id)
);

CREATE TABLE sync_log (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    sync_timestamp DATETIME2 DEFAULT GETDATE(),
    sync_type NVARCHAR(50),  -- 'timer', 'webhook', 'manual'
    records_processed INT,
    records_inserted INT,
    records_updated INT,
    success BIT,
    error_message NVARCHAR(MAX),
    execution_time_ms INT
);

-- Create indexes for better performance
CREATE INDEX IX_spend_records_date ON spend_records(date_recorded);
CREATE INDEX IX_spend_records_sync_id ON spend_records(sheet_sync_id);
CREATE INDEX IX_sync_log_timestamp ON sync_log(sync_timestamp);
CREATE INDEX IX_sync_log_success ON sync_log(success, sync_timestamp);

-- Create a view for easy reporting
CREATE VIEW v_recent_spend_summary AS
SELECT 
    DATE(date_recorded) as date_recorded,
    spend_type,
    COUNT(*) as transaction_count,
    SUM(ISNULL(ingoing, 0)) as total_ingoing,
    SUM(ISNULL(outgoing, 0)) as total_outgoing,
    MAX(balance) as end_balance
FROM spend_records 
WHERE date_recorded >= DATEADD(day, -30, GETDATE())
GROUP BY DATE(date_recorded), spend_type
ORDER BY date_recorded DESC, spend_type;

-- Create a view for sync monitoring
CREATE VIEW v_sync_summary AS
SELECT 
    sync_type,
    COUNT(*) as total_syncs,
    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_syncs,
    SUM(records_processed) as total_records_processed,
    AVG(execution_time_ms) as avg_execution_time_ms,
    MAX(sync_timestamp) as last_sync_time
FROM sync_log
WHERE sync_timestamp >= DATEADD(day, -7, GETDATE())
GROUP BY sync_type;

-- Sample queries for monitoring

-- Check recent sync activity
-- SELECT TOP 10 * FROM sync_log ORDER BY sync_timestamp DESC;

-- Check recent spend records
-- SELECT TOP 10 * FROM spend_records ORDER BY updated_at DESC;

-- Get sync success rate
-- SELECT 
--     sync_type,
--     successful_syncs,
--     total_syncs,
--     CAST(successful_syncs AS FLOAT) / total_syncs * 100 as success_rate_percent
-- FROM v_sync_summary;

-- Get spending summary by type
-- SELECT * FROM v_recent_spend_summary;

PRINT 'SpendTracker database setup completed successfully!';