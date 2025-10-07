

USE SQLAdmin
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('spSQLServer_Prune') IS NOT NULL
	DROP PROCEDURE [dbo].[spSQLServer_Prune]
GO

CREATE PROCEDURE dbo.spSQLServer_Prune
(
  @keep_days INT = 14
)
/*************************************************************

Author:			Chris Dunbar

Date:			2025-08-21

SDP Ticket:		PJT-70

Purpose:		Deletes data older than a certain date range.

**************************************************************/
AS
BEGIN TRY

  SET NOCOUNT ON;

  DELETE FROM dbo.SQLWatchdog
  WHERE dtSQLWatchdog < DATEADD(day, -@keep_days, SYSUTCDATETIME());

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
