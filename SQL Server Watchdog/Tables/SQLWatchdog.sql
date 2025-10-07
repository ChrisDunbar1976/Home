
USE SQLAdmin
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* Create or extend dbo.SQLWatchdog */
IF OBJECT_ID('dbo.SQLWatchdog','U') IS NULL
BEGIN
CREATE TABLE dbo.SQLWatchdog
(
    SQLWatchdogId             INT IDENTITY(1,1) NOT NULL,
    dtSQLWatchdog             DATETIME2 NOT NULL
        CONSTRAINT DF_SQLWatchdog_dtSQLWatchdog DEFAULT SYSUTCDATETIME(),
    total_server_mem_kb       BIGINT     NULL,
    target_server_mem_kb      BIGINT     NULL,
    memory_grants_pending     INT        NULL,
    page_life_expectancy      INT        NULL,
    os_total_mb               INT        NULL,
    os_available_mb           INT        NULL,
    sql_physical_in_use_mb    INT        NULL,
    sql_mem_utilization_pct   TINYINT    NULL,
    CONSTRAINT PK_SQLWatchdog PRIMARY KEY CLUSTERED (SQLWatchdogId)
);
END;


-- Clustered index on time (desc) for fast recent reads
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.SQLWatchdog') AND name='CX_SQLWatchdog_dtSQLWatchdog')
  CREATE CLUSTERED INDEX CX_SQLWatchdog_dtSQLWatchdog ON dbo.SQLWatchdog(dtSQLWatchdog DESC);
GO
