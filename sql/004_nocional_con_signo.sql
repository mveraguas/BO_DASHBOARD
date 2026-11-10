USE DashboardOperaciones;
SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('dbo.Trades') AND name='CK_Trades_Importes')
    ALTER TABLE dbo.Trades DROP CONSTRAINT CK_Trades_Importes;
ALTER TABLE dbo.Trades WITH CHECK ADD CONSTRAINT CK_Trades_Importes CHECK(TipoCambio>0);
-- No modifica montos existentes. Nocional DECIMAL ya admite signos y cero.
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
THROW;
END CATCH;
-- Verificación reversible: guardar y leer un negativo, restaurando siempre el registro.
BEGIN TRANSACTION;
UPDATE dbo.Trades SET Nocional=-ABS(Nocional) WHERE TradeID='DEMO-TRD-004';
SELECT TradeID,Nocional FROM dbo.Trades WHERE TradeID='DEMO-TRD-004';
ROLLBACK TRANSACTION;
