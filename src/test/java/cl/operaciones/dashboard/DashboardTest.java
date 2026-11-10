package cl.operaciones.dashboard;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "dashboard.mode=demo")
@AutoConfigureMockMvc
class DashboardTest {
    @Autowired MockMvc mvc;
    @Test void demoIsExplicitAndIncludesBothTradeLegs() throws Exception {
        mvc.perform(get("/api/mensajeria"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.origen").value("demo"))
            .andExpect(jsonPath("$.mensajes.length()").value(12))
            .andExpect(jsonPath("$.mensajes[0].tradeID").value("TRD-001"))
            .andExpect(jsonPath("$.mensajes[1].tradeID").value("TRD-001"))
            .andExpect(jsonPath("$.mensajes[0].messageID").value("MSG-0001"))
            .andExpect(jsonPath("$.mensajes[1].messageID").value("MSG-0002"));
    }
    @Test void demoCoversEveryMessageState() throws Exception {
        mvc.perform(get("/api/mensajeria"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.mensajes[*].estadoMensaje", org.hamcrest.Matchers.hasItems("PENDING_MATCH", "REJECTED", "MATCH", "LOADED")));
    }
    @Test void servesDashboard() throws Exception {
        mvc.perform(get("/index.html")).andExpect(status().isOk())
            .andExpect(content().string(org.hamcrest.Matchers.containsString("Monitor de")));
    }
}
