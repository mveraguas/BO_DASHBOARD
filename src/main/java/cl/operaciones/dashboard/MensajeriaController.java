package cl.operaciones.dashboard;

import java.math.BigDecimal;
import java.sql.DriverManager;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class MensajeriaController {
    private static final Logger log = LoggerFactory.getLogger(MensajeriaController.class);
    @Value("${dashboard.mode}") private String mode;
    @Value("${dashboard.sql.url}") private String url;
    @Value("${dashboard.sql.user}") private String user;
    @Value("${dashboard.sql.password}") private String password;

    public record Respuesta(String origen, List<Mensaje> mensajes) {}

    @GetMapping("/api/mensajeria")
    public Respuesta mensajes() {
        if ("demo".equalsIgnoreCase(mode)) return new Respuesta("demo", ejemplos());
        if (!"sqlserver".equalsIgnoreCase(mode))
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Modo de datos desconocido");
        var properties = new java.util.Properties();
        if (!user.isBlank()) { properties.setProperty("user", user); properties.setProperty("password", password); }
        String sql = """
            SELECT TOP (10001) IdMensaje, MessageID, TradeID, TipoMensaje, BancoEmisor,
                BancoReceptor, FechaHoraIngreso, MonedaCompra, NominalCompra,
                MonedaVenta, NominalVenta, TipoCambio, ConvencionTipoCambio,
                FechaOperacion, FechaLiquidacion, PlazoDias, EstadoMensaje
            FROM dbo.Mensajeria ORDER BY FechaHoraIngreso DESC, IdMensaje DESC
            """;
        try (var connection = DriverManager.getConnection(url, properties);
             var statement = connection.prepareStatement(sql)) {
            statement.setQueryTimeout(15);
            try (var rs = statement.executeQuery()) {
                List<Mensaje> rows = new ArrayList<>();
                while (rs.next()) rows.add(new Mensaje(rs.getLong("IdMensaje"), rs.getString("MessageID"),
                    rs.getString("TradeID"), rs.getString("TipoMensaje"), rs.getString("BancoEmisor"),
                    rs.getString("BancoReceptor"), rs.getTimestamp("FechaHoraIngreso").toLocalDateTime(),
                    rs.getString("MonedaCompra"), rs.getBigDecimal("NominalCompra"), rs.getString("MonedaVenta"),
                    rs.getBigDecimal("NominalVenta"), rs.getBigDecimal("TipoCambio"), rs.getString("ConvencionTipoCambio"),
                    rs.getDate("FechaOperacion").toLocalDate(), rs.getDate("FechaLiquidacion").toLocalDate(),
                    rs.getInt("PlazoDias"), rs.getString("EstadoMensaje")));
                if (rows.size() > 10000) throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Hay más de 10.000 mensajes. Se requiere paginación en servidor para este volumen.");
                return new Respuesta("sqlserver", rows);
            }
        } catch (java.sql.SQLException ex) {
            log.error("No fue posible consultar Mensajeria. Código SQL: {}, estado: {}", ex.getErrorCode(), ex.getSQLState());
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "No fue posible consultar SQL Server. Revisa conexión, credenciales y tabla Mensajeria.");
        }
    }

    static List<Mensaje> ejemplos() {
        return List.of(
            ejemplo(1,"TRD-001","BANCO A","BANCO B","09:00:00","USD","100000","CLP","95000000","950",2),
            ejemplo(2,"TRD-001","BANCO B","BANCO A","09:03:00","CLP","95000000","USD","100000","950",2),
            ejemplo(3,"TRD-002","BANCO A","BANCO C","09:10:00","USD","250000","CLP","238125000","952.5",3),
            ejemplo(4,"TRD-003","BANCO B","BANCO D","09:15:00","EUR","80000","USD","88000","1.1",2),
            ejemplo(5,"TRD-004","BANCO A","BANCO D","10:00:00","USD","150000","CLP","142500000","950",2,"MATCH"),
            ejemplo(6,"TRD-004","BANCO D","BANCO A","10:02:00","CLP","142500000","USD","150000","950",2,"MATCH"),
            ejemplo(7,"TRD-005","BANCO B","BANCO C","11:00:00","USD","200000","CLP","190000000","950",2,"LOADED"),
            ejemplo(8,"TRD-005","BANCO C","BANCO B","11:04:00","CLP","190000000","USD","200000","950",2,"LOADED"),
            ejemplo(9,"TRD-006","BANCO C","BANCO D","12:00:00","EUR","50000","USD","55000","1.1",2,"REJECTED"),
            ejemplo(10,"TRD-006","BANCO D","BANCO C","12:03:00","USD","55000","EUR","50000","1.1",2,"REJECTED"),
            ejemplo(11,"TRD-007","BANCO A","BANCO C","13:00:00","USD","75000","CLP","71250000","950",3,"PENDING_MATCH"),
            ejemplo(12,"TRD-008","BANCO B","BANCO D","14:00:00","EUR","60000","USD","66000","1.1",2,"PENDING_MATCH"));
    }
    private static Mensaje ejemplo(long id,String trade,String emisor,String receptor,String hora,
        String compra,String nominalCompra,String venta,String nominalVenta,String cambio,int plazo) {
        return ejemplo(id,trade,emisor,receptor,hora,compra,nominalCompra,venta,nominalVenta,cambio,plazo,"PENDING_MATCH");
    }
    private static Mensaje ejemplo(long id,String trade,String emisor,String receptor,String hora,
        String compra,String nominalCompra,String venta,String nominalVenta,String cambio,int plazo,String estado) {
        LocalDate fecha = LocalDate.of(2026,11,2);
        return new Mensaje(id,String.format("MSG-%04d",id),trade,"MT300",emisor,receptor,
            LocalDateTime.parse(fecha+"T"+hora),compra,new BigDecimal(nominalCompra),venta,
            new BigDecimal(nominalVenta),new BigDecimal(cambio),("EUR".equals(compra) || "EUR".equals(venta))?"USD por EUR":"CLP por USD",
            fecha,fecha.plusDays(plazo),plazo,estado);
    }
}
