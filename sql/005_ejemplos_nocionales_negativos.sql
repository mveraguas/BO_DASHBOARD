USE DashboardOperaciones;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
-- Solo ejemplos conocidos. Reejecutable: no invierte nuevamente los signos.
UPDATE dbo.Trades
SET Nocional=-ABS(Nocional)
WHERE TradeID IN ('DEMO-TRD-004','DEMO-TRD-008','DEMO-TRD-009','DEMO-TRD-013');
COMMIT TRANSACTION;
SELECT BancoEmisor,Moneda,COUNT(*) AS Operaciones,
       SUM(ABS(Nocional)) AS Bruto,SUM(Nocional) AS Neto
FROM dbo.Trades
WHERE Estado='Cleared'
AND FechaHoraIngreso>=CAST(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time') AS datetime2)
AND FechaHoraIngreso<DATEADD(day,1,CAST(CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific SA Standard Time') AS datetime2))
GROUP BY BancoEmisor,Moneda ORDER BY Moneda,BancoEmisor;
