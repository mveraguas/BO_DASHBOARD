USE DashboardOperaciones;
SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;
-- La columna ya existe. Se conservan estados vÃ¡lidos y los registros existentes.
UPDATE dbo.Mensajeria SET EstadoMensaje='PENDING_MATCH' WHERE EstadoMensaje='RECIBIDO';
IF EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE EstadoMensaje IS NULL OR EstadoMensaje COLLATE Latin1_General_100_BIN2 NOT IN ('PENDING_MATCH','REJECTED','MATCH','LOADED'))
    THROW 50001, 'Hay estados desconocidos. Revisarlos antes de aplicar la migraciÃ³n.', 1;
DECLARE @defaultName sysname;
SELECT @defaultName=dc.name FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id=dc.parent_object_id AND c.column_id=dc.parent_column_id
WHERE dc.parent_object_id=OBJECT_ID('dbo.Mensajeria') AND c.name='EstadoMensaje';
IF @defaultName IS NOT NULL
BEGIN
    DECLARE @dropDefault nvarchar(4000)=N'ALTER TABLE dbo.Mensajeria DROP CONSTRAINT '+QUOTENAME(@defaultName);
    EXEC sys.sp_executesql @dropDefault;
END;
ALTER TABLE dbo.Mensajeria ADD CONSTRAINT DF_Mensajeria_EstadoMensaje DEFAULT 'PENDING_MATCH' FOR EstadoMensaje;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Mensajeria_EstadoMensaje' AND parent_object_id=OBJECT_ID('dbo.Mensajeria'))
    ALTER TABLE dbo.Mensajeria WITH CHECK ADD CONSTRAINT CK_Mensajeria_EstadoMensaje
    CHECK (EstadoMensaje IS NOT NULL AND EstadoMensaje COLLATE Latin1_General_100_BIN2 IN ('PENDING_MATCH','REJECTED','MATCH','LOADED'));
-- Ejemplos ficticios del 2 de noviembre de 2026. Reejecutable sin duplicar MessageID.
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0005')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0005','TRD-004','MT300','BANCO A','BANCO D','2026-11-02T10:00:00','USD',150000,'CLP',142500000,950,'CLP por USD','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'MATCH');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0006')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0006','TRD-004','MT300','BANCO D','BANCO A','2026-11-02T10:02:00','CLP',142500000,'USD',150000,950,'CLP por USD','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'MATCH');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0007')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0007','TRD-005','MT300','BANCO B','BANCO C','2026-11-02T11:00:00','USD',200000,'CLP',190000000,950,'CLP por USD','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'LOADED');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0008')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0008','TRD-005','MT300','BANCO C','BANCO B','2026-11-02T11:04:00','CLP',190000000,'USD',200000,950,'CLP por USD','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'LOADED');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0009')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0009','TRD-006','MT300','BANCO C','BANCO D','2026-11-02T12:00:00','EUR',50000,'USD',55000,1.1,'USD por EUR','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'REJECTED');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0010')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0010','TRD-006','MT300','BANCO D','BANCO C','2026-11-02T12:03:00','USD',55000,'EUR',50000,1.1,'USD por EUR','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'REJECTED');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0011')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0011','TRD-007','MT300','BANCO A','BANCO C','2026-11-02T13:00:00','USD',75000,'CLP',71250000,950,'CLP por USD','2026-11-02',DATEADD(DAY,3,CAST('2026-11-02' AS date)),'PENDING_MATCH');
IF NOT EXISTS (SELECT 1 FROM dbo.Mensajeria WHERE MessageID='MSG-0012')
INSERT INTO dbo.Mensajeria (MessageID,TradeID,TipoMensaje,BancoEmisor,BancoReceptor,FechaHoraIngreso,MonedaCompra,NominalCompra,MonedaVenta,NominalVenta,TipoCambio,ConvencionTipoCambio,FechaOperacion,FechaLiquidacion,EstadoMensaje)
VALUES ('MSG-0012','TRD-008','MT300','BANCO B','BANCO D','2026-11-02T14:00:00','EUR',60000,'USD',66000,1.1,'USD por EUR','2026-11-02',DATEADD(DAY,2,CAST('2026-11-02' AS date)),'PENDING_MATCH');
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
THROW;
END CATCH;
SELECT EstadoMensaje,COUNT(*) AS Cantidad FROM dbo.Mensajeria GROUP BY EstadoMensaje;
