package cl.operaciones.dashboard;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest(properties="dashboard.mode=demo")
@AutoConfigureMockMvc
class TradesTest {
    @Autowired MockMvc mvc;
    @Test void todayContainsOnlyClearedTradesGroupedBySender() throws Exception {
        mvc.perform(get("/api/trades/cleared-hoy"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.origen").value("demo"))
            .andExpect(jsonPath("$.zonaHoraria").value("America/Santiago"))
            .andExpect(jsonPath("$.fecha").value(java.time.LocalDate.now(java.time.ZoneId.of("America/Santiago")).toString()))
            .andExpect(jsonPath("$.bancos.length()").value(6))
            .andExpect(jsonPath("$.detalles.length()").value(16))
            .andExpect(jsonPath("$.detalles[?(@.estado == 'REJECTED_HRC')]", org.hamcrest.Matchers.hasSize(4)))
            .andExpect(jsonPath("$.detalles[0].contraparte").value("BECH"))
            .andExpect(jsonPath("$.bancos[0].moneda").value("CLF/CLP"))
            .andExpect(jsonPath("$.bancos[0].nocionalAbsoluto").value(1400))
            .andExpect(jsonPath("$.bancos[0].nocionalNeto").value(-1400))
            .andExpect(jsonPath("$.bancos[1].nocionalNeto").value(1800))
            .andExpect(jsonPath("$.bancos[0].banco").value("BCHI"))
            .andExpect(jsonPath("$.bancos[0].cantidad").value(1))
            .andExpect(jsonPath("$.bancos[1].cantidad").value(3))
            .andExpect(jsonPath("$.bancos[2].cantidad").value(1));
    }
}
