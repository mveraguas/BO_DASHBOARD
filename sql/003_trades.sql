USE DashboardOperaciones;
SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Trades','U') IS NULL
BEGIN
CREATE TABLE dbo.Trades (
    TradeID VARCHAR(50) NOT NULL CONSTRAINT PK_Trades PRIMARY KEY,
    BancoEmisor VARCHAR(12) NOT NULL,
    Contraparte VARCHAR(12) NOT NULL,
    Nocional DECIMAL(20,4) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFixing DATE NOT NULL,
    FechaMatured DATE NOT NULL,
    TipoCambio DECIMAL(20,8) NOT NULL,
    Moneda VARCHAR(7) NOT NULL,
    Servicio VARCHAR(30) NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    -- Hora local operacional de Chile, consistente con el dashboard.
    FechaHoraIngreso DATETIME2(0) NOT NULL CONSTRAINT DF_Trades_Ingreso
        DEFAULT (CONVERT(datetime2(0), SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time')),
    CONSTRAINT CK_Trades_Importes CHECK(TipoCambio>0),
    CONSTRAINT CK_Trades_Monedas CHECK(Moneda IN ('CLF/CLP','USD/CLP')),
    CONSTRAINT CK_Trades_Estados CHECK(Estado COLLATE Latin1_General_100_BIN2 IN ('Matured','Cleared','REJECTED_HRC')),
    CONSTRAINT CK_Trades_Fechas CHECK(FechaInicio<=FechaFixing AND FechaFixing<=FechaMatured),
    CONSTRAINT CK_Trades_Bancos CHECK(BancoEmisor<>Contraparte)
);
CREATE INDEX IX_Trades_EstadoIngreso ON dbo.Trades(Estado,FechaHoraIngreso) INCLUDE(BancoEmisor);
END;
DECLARE @hoy DATE=CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time');
-- Datos ficticios: 16 ingresos de hoy y 4 de ayer. Nocional en la primera moneda;
-- TipoCambio en CLP por unidad de CLF o USD. Servicio de ejemplo NDF.
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-001')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-001','BCHI','BECH',125000,DATEADD(day,0,@hoy),DATEADD(day,29,@hoy),DATEADD(day,31,@hoy),940.5,'USD/CLP','NDF','REJECTED_HRC',DATEADD(minute,495,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-002')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-002','BKSA','BICH',1200,DATEADD(day,0,@hoy),DATEADD(day,30,@hoy),DATEADD(day,32,@hoy),38020,'CLF/CLP','NDF','Cleared',DATEADD(minute,510,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-003')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-003','CRED','BSCH',175000,DATEADD(day,0,@hoy),DATEADD(day,31,@hoy),DATEADD(day,33,@hoy),941.5,'USD/CLP','NDF','Cleared',DATEADD(minute,525,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-004')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-004','BCHI','BECH',1400,DATEADD(day,0,@hoy),DATEADD(day,32,@hoy),DATEADD(day,34,@hoy),38040,'CLF/CLP','NDF','Cleared',DATEADD(minute,540,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-005')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-005','BKSA','BICH',225000,DATEADD(day,-35,@hoy),DATEADD(day,-2,@hoy),DATEADD(day,-1,@hoy),942.5,'USD/CLP','NDF','Matured',DATEADD(minute,555,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-006')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-006','CRED','BSCH',1600,DATEADD(day,0,@hoy),DATEADD(day,34,@hoy),DATEADD(day,36,@hoy),38060,'CLF/CLP','NDF','REJECTED_HRC',DATEADD(minute,570,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-007')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-007','BCHI','BECH',275000,DATEADD(day,0,@hoy),DATEADD(day,35,@hoy),DATEADD(day,37,@hoy),943.5,'USD/CLP','NDF','Cleared',DATEADD(minute,585,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-008')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-008','BKSA','BICH',1800,DATEADD(day,0,@hoy),DATEADD(day,36,@hoy),DATEADD(day,38,@hoy),38080,'CLF/CLP','NDF','Cleared',DATEADD(minute,600,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-009')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-009','CRED','BSCH',325000,DATEADD(day,0,@hoy),DATEADD(day,37,@hoy),DATEADD(day,39,@hoy),944.5,'USD/CLP','NDF','Cleared',DATEADD(minute,615,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-010')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-010','BCHI','BECH',2000,DATEADD(day,-35,@hoy),DATEADD(day,-2,@hoy),DATEADD(day,-1,@hoy),38100,'CLF/CLP','NDF','Matured',DATEADD(minute,630,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-011')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-011','BKSA','BICH',375000,DATEADD(day,0,@hoy),DATEADD(day,39,@hoy),DATEADD(day,41,@hoy),945.5,'USD/CLP','NDF','REJECTED_HRC',DATEADD(minute,645,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-012')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-012','CRED','BSCH',2200,DATEADD(day,0,@hoy),DATEADD(day,40,@hoy),DATEADD(day,42,@hoy),38120,'CLF/CLP','NDF','Cleared',DATEADD(minute,660,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-013')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-013','BCHI','BECH',425000,DATEADD(day,0,@hoy),DATEADD(day,41,@hoy),DATEADD(day,43,@hoy),946.5,'USD/CLP','NDF','Cleared',DATEADD(minute,675,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-014')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-014','BKSA','BICH',2400,DATEADD(day,0,@hoy),DATEADD(day,42,@hoy),DATEADD(day,44,@hoy),38140,'CLF/CLP','NDF','Cleared',DATEADD(minute,690,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-015')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-015','CRED','BSCH',475000,DATEADD(day,-35,@hoy),DATEADD(day,-2,@hoy),DATEADD(day,-1,@hoy),947.5,'USD/CLP','NDF','Matured',DATEADD(minute,705,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-016')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-016','BCHI','BECH',2600,DATEADD(day,0,@hoy),DATEADD(day,44,@hoy),DATEADD(day,46,@hoy),38160,'CLF/CLP','NDF','REJECTED_HRC',DATEADD(minute,720,CAST(DATEADD(day,0,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-017')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-017','BKSA','BICH',525000,DATEADD(day,-1,@hoy),DATEADD(day,45,@hoy),DATEADD(day,47,@hoy),948.5,'USD/CLP','NDF','Cleared',DATEADD(minute,735,CAST(DATEADD(day,-1,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-018')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-018','CRED','BSCH',2800,DATEADD(day,-1,@hoy),DATEADD(day,46,@hoy),DATEADD(day,48,@hoy),38180,'CLF/CLP','NDF','Cleared',DATEADD(minute,750,CAST(DATEADD(day,-1,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-019')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-019','BCHI','BECH',575000,DATEADD(day,-1,@hoy),DATEADD(day,47,@hoy),DATEADD(day,49,@hoy),949.5,'USD/CLP','NDF','Cleared',DATEADD(minute,765,CAST(DATEADD(day,-1,@hoy) AS datetime2(0))));
IF NOT EXISTS(SELECT 1 FROM dbo.Trades WHERE TradeID='DEMO-TRD-020')
INSERT INTO dbo.Trades(TradeID,BancoEmisor,Contraparte,Nocional,FechaInicio,FechaFixing,FechaMatured,TipoCambio,Moneda,Servicio,Estado,FechaHoraIngreso)
VALUES('DEMO-TRD-020','BKSA','BICH',3000,DATEADD(day,-35,@hoy),DATEADD(day,-2,@hoy),DATEADD(day,-1,@hoy),38200,'CLF/CLP','NDF','Matured',DATEADD(minute,780,CAST(DATEADD(day,-1,@hoy) AS datetime2(0))));
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
THROW;
END CATCH;
SELECT COUNT(*) AS TotalTrades FROM dbo.Trades;
SELECT BancoEmisor,COUNT(*) AS ClearedHoy FROM dbo.Trades
WHERE Estado='Cleared' AND FechaHoraIngreso>=CAST(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time') AS datetime2)
AND FechaHoraIngreso<DATEADD(day,1,CAST(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time') AS datetime2))
GROUP BY BancoEmisor ORDER BY BancoEmisor;
