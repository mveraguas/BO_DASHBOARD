package cl.operaciones.dashboard;

import java.sql.DriverManager;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class TradesController {
    @Value("${dashboard.mode}") private String mode;
    @Value("${dashboard.sql.url}") private String url;
    @Value("${dashboard.sql.user}") private String user;
    @Value("${dashboard.sql.password}") private String password;
    public record Banco(String banco, String moneda, long cantidad, java.math.BigDecimal nocionalAbsoluto, java.math.BigDecimal nocionalNeto) {}
    public record Detalle(String banco, String contraparte, String moneda, String estado, long cantidad, java.math.BigDecimal nocionalAbsoluto) {}
    public record Resumen(String origen, LocalDate fecha, String zonaHoraria, List<Banco> bancos, List<Detalle> detalles) {}
    @GetMapping("/api/trades/cleared-hoy")
    public Resumen clearedHoy() {
        LocalDate hoy=LocalDate.now(ZoneId.of("America/Santiago"));
        if ("demo".equalsIgnoreCase(mode)) return new Resumen("demo",hoy,"America/Santiago",demo(),demoDetalles());
        if (!"sqlserver".equalsIgnoreCase(mode)) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Modo desconocido");
        var properties=new java.util.Properties();
        if (!user.isBlank()) {properties.setProperty("user",user);properties.setProperty("password",password);}
        String sql="""
            WITH Bancos AS (
                SELECT BancoEmisor AS Banco FROM dbo.Trades
                UNION SELECT Banco FROM (VALUES ('BCHI'),('BKSA'),('CRED')) v(Banco)
            )
            SELECT b.Banco, m.Moneda, COUNT(t.TradeID) AS Cantidad, COALESCE(SUM(ABS(t.Nocional)),0) AS NocionalAbsoluto, COALESCE(SUM(t.Nocional),0) AS NocionalNeto
            FROM Bancos b CROSS JOIN (VALUES ('CLF/CLP'),('USD/CLP')) m(Moneda)
            LEFT JOIN dbo.Trades t ON t.BancoEmisor=b.Banco AND t.Moneda=m.Moneda
              AND t.Estado='Cleared' AND t.FechaHoraIngreso>=? AND t.FechaHoraIngreso<?
            GROUP BY b.Banco,m.Moneda ORDER BY m.Moneda,b.Banco
            """;
        try(var connection=DriverManager.getConnection(url,properties);var statement=connection.prepareStatement(sql)) {
            statement.setTimestamp(1,java.sql.Timestamp.valueOf(hoy.atStartOfDay()));
            statement.setTimestamp(2,java.sql.Timestamp.valueOf(hoy.plusDays(1).atStartOfDay()));
            statement.setQueryTimeout(15);
            try(var rs=statement.executeQuery()) {
                List<Banco> bancos=new ArrayList<>();
                while(rs.next()) bancos.add(new Banco(rs.getString("Banco"),rs.getString("Moneda"),rs.getLong("Cantidad"),rs.getBigDecimal("NocionalAbsoluto"),rs.getBigDecimal("NocionalNeto")));
                String detailSql="""
                    SELECT BancoEmisor,Contraparte,Moneda,Estado,COUNT(*) AS Cantidad,SUM(ABS(Nocional)) AS Nocional
                    FROM dbo.Trades WHERE FechaHoraIngreso>=? AND FechaHoraIngreso<?
                    GROUP BY BancoEmisor,Contraparte,Moneda,Estado
                    ORDER BY BancoEmisor,Contraparte,Moneda,Estado
                    """;
                List<Detalle> detalles=new ArrayList<>();
                try(var detailStatement=connection.prepareStatement(detailSql)) {
                    detailStatement.setTimestamp(1,java.sql.Timestamp.valueOf(hoy.atStartOfDay()));
                    detailStatement.setTimestamp(2,java.sql.Timestamp.valueOf(hoy.plusDays(1).atStartOfDay()));
                    detailStatement.setQueryTimeout(15);
                    try(var detail=detailStatement.executeQuery()) {
                        while(detail.next()) detalles.add(new Detalle(detail.getString("BancoEmisor"),detail.getString("Contraparte"),detail.getString("Moneda"),detail.getString("Estado"),detail.getLong("Cantidad"),detail.getBigDecimal("Nocional")));
                    }
                }
                return new Resumen("sqlserver",hoy,"America/Santiago",bancos,detalles);
            }
        } catch(java.sql.SQLException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"No fue posible consultar Trades en SQL Server.");
        }
    }
    static List<Detalle> demoDetalles() {
        List<Detalle> result=new ArrayList<>();
        for(int i=1;i<=16;i++) result.add(new Detalle(
            List.of("BCHI","BKSA","CRED").get((i-1)%3),
            List.of("BECH","BICH","BSCH").get((i-1)%3),
            i%2==0?"CLF/CLP":"USD/CLP", i%5==0?"Matured":i%5==1?"REJECTED_HRC":"Cleared",1,
            java.math.BigDecimal.valueOf(i%2==0?1000+i*100:100000+i*25000)));
        return result;
    }
    static List<Banco> demo() {
        List<Banco> rows=new ArrayList<>();
        for(String moneda:List.of("CLF/CLP","USD/CLP")) for(String banco:List.of("BCHI","BKSA","CRED")) {
            long count=0;
            java.math.BigDecimal total=java.math.BigDecimal.ZERO,neto=java.math.BigDecimal.ZERO;
            for(int i=1;i<=16;i++) if(i%5!=0 && i%5!=1
                && banco.equals(List.of("BCHI","BKSA","CRED").get((i-1)%3))
                && moneda.equals(i%2==0?"CLF/CLP":"USD/CLP")) {
                count++;
                java.math.BigDecimal amount=java.math.BigDecimal.valueOf(i%2==0?1000+i*100:100000+i*25000);
                if(i%4<2) amount=amount.negate();
                total=total.add(amount.abs());
                neto=neto.add(amount);
            }
            rows.add(new Banco(banco,moneda,count,total,neto));
        }
        return rows;
    }
}
