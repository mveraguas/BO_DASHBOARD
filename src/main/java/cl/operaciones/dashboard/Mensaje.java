package cl.operaciones.dashboard;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record Mensaje(long idMensaje, String messageID, String tradeID,
    String tipoMensaje, String bancoEmisor, String bancoReceptor,
    LocalDateTime fechaHoraIngreso, String monedaCompra, BigDecimal nominalCompra,
    String monedaVenta, BigDecimal nominalVenta, BigDecimal tipoCambio,
    String convencionTipoCambio, LocalDate fechaOperacion,
    LocalDate fechaLiquidacion, int plazoDias, String estadoMensaje) {}
