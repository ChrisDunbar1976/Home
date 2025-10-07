
USE SQLAdmin
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Custom message 50051 (only once) */
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50051 AND language_id = 1033)
  EXEC sys.sp_addmessage
       @msgnum = 50051,
       @severity = 16,
       @msgtext = N'SQLWatchdog Alert: Low OS memory (<= %d MB) or memory grants pending (>%d) in the last %d minute(s). Latest OS free MB=%d; Max Grants Pending=%d.',
       @lang = 'us_english',
       @with_log = 'true';
ELSE
  EXEC sys.sp_altermessage 50051, 'WITH_LOG', 'true';
GO

IF OBJECT_ID('spSQLWatchdog_Check') IS NOT NULL
	DROP PROCEDURE [dbo].[spSQLWatchdog_Check]
GO

CREATE PROCEDURE dbo.spSQLWatchdog_Check
(
	  @min_os_available_mb      int = 2048,     -- threshold
	  @consecutive_minutes      int = 2,        -- require N consecutive minutes
	  @grants_pending_threshold int = 0         -- any > 0 is a concern
)
/*************************************************************

Author:			Chris Dunbar

Date:			2025-08-21

SDP Ticket:		PJT-70

Purpose:		Creates a RAISERROR used for a SQL Agent Job alert.

**************************************************************/
AS
BEGIN TRY
  SET NOCOUNT ON;

  -- Pull latest N rows (one per minute) without using a CTE
  IF OBJECT_ID('tempdb..#lastN') IS NOT NULL DROP TABLE #lastN;

  SELECT TOP (@consecutive_minutes)
         dtSQLWatchdog, os_available_mb, memory_grants_pending
  INTO #lastN
  FROM dbo.SQLWatchdog
  ORDER BY dtSQLWatchdog DESC;

  DECLARE
      @low_os_count int,
      @min_os       int,
      @max_grants   int;

  SELECT
      @low_os_count = SUM(CASE WHEN os_available_mb IS NOT NULL
                                    AND os_available_mb <= @min_os_available_mb
                               THEN 1 ELSE 0 END),
      @min_os       = MIN(os_available_mb),
      @max_grants   = MAX(ISNULL(memory_grants_pending,0))
  FROM #lastN;

  -- Default NULLs so RAISERROR gets simple scalars
  SET @min_os     = ISNULL(@min_os, -1);
  SET @max_grants = ISNULL(@max_grants, -1);

  IF (@low_os_count >= @consecutive_minutes) OR (@max_grants > @grants_pending_threshold)
  BEGIN
      -- Fires the Agent Alert listening on message_id 50051
      RAISERROR (50051, 16, 1,
                 @min_os_available_mb,
                 @grants_pending_threshold,
                 @consecutive_minutes,
                 @min_os,
                 @max_grants) WITH LOG;
  END

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


