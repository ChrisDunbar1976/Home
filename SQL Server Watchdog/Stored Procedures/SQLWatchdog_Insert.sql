
USE SQLAdmin
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('spSQLWatchdog_Insert') IS NOT NULL
	DROP PROCEDURE [dbo].[spSQLWatchdog_Insert]
GO

CREATE PROCEDURE dbo.spSQLWatchdog_Insert
/*************************************************************

Author:			Chris Dunbar

Date:			2025-08-21

SDP Ticket:		PJT-70

Purpose:		Insert Performance data into dbo.SQLWatchdog

**************************************************************/
AS
BEGIN TRY

  SET NOCOUNT ON;


  INSERT dbo.SQLWatchdog
  (
    total_server_mem_kb, target_server_mem_kb, memory_grants_pending, page_life_expectancy,
    os_total_mb, os_available_mb, sql_physical_in_use_mb, sql_mem_utilization_pct
  )
  SELECT
    MAX(CASE WHEN pc.counter_name = 'Total Server Memory (KB)'
             AND pc.object_name LIKE '%Memory Manager%' THEN pc.cntr_value END),
    MAX(CASE WHEN pc.counter_name = 'Target Server Memory (KB)'
             AND pc.object_name LIKE '%Memory Manager%' THEN pc.cntr_value END),
    MAX(CASE WHEN pc.counter_name = 'Memory Grants Pending'
             AND pc.object_name LIKE '%Memory Manager%' THEN pc.cntr_value END),
    MAX(CASE WHEN pc.counter_name = 'Page life expectancy'
             AND pc.object_name LIKE '%Buffer Manager%' THEN pc.cntr_value END),
    MAX(sysmem.total_physical_memory_kb)/1024,
    MAX(sysmem.available_physical_memory_kb)/1024,
    MAX(procMem.physical_memory_in_use_kb)/1024,
    MAX(procMem.memory_utilization_percentage)
  FROM sys.dm_os_performance_counters AS pc
  CROSS JOIN sys.dm_os_sys_memory     AS sysmem
  CROSS JOIN sys.dm_os_process_memory AS procMem;

END TRY

BEGIN CATCH

    DECLARE @errorMessage NVARCHAR(4000)
      , @errorNumber INT
      , @errorSeverity INT
      , @errorState INT
      , @errorProcedure NVARCHAR(200)
      , @errorLine INT
      , @exceptionAnnotation NVARCHAR(200)

    SELECT @exceptionAnnotation = OBJECT_NAME(@@PROCID)

    IF OBJECT_ID('dbo.Exception_Log') IS NOT NULL
        EXECUTE Engineering.dbo.Exception_Log @errorMessage OUTPUT, @errorNumber OUTPUT, @errorSeverity OUTPUT, @errorState OUTPUT, @errorProcedure OUTPUT, @errorLine OUTPUT, @exceptionAnnotation
    ELSE
    BEGIN
        SELECT @errorMessage = ERROR_MESSAGE(),
               @errorNumber = ERROR_NUMBER(),
               @errorSeverity = ERROR_SEVERITY(),
               @errorState = ERROR_STATE(),
               @errorProcedure = ERROR_PROCEDURE(),
               @errorLine = ERROR_LINE()
    END

    RAISERROR (@errorMessage , @errorSeverity , 1 , @errorNumber ,
        @errorSeverity ,
        @errorState ,
        @errorProcedure ,
        @errorLine
    );
END CATCH
GO

