# Dashboard de operaciones MT300

Proyecto Java 17 / Spring Boot 3.5.7. Interfaz HTML, CSS y JavaScript servida por Spring Boot, sin Node ni dependencias visuales externas.

## Ejecutar

Desde PowerShell en esta carpeta:

    powershell -ExecutionPolicy Bypass -File .\iniciar.ps1

Abrir http://localhost:8080. Detener con Ctrl+C.

El modo predeterminado es DEMO: contiene doce mensajes ficticios del ejemplo y siempre muestra un aviso. No consulta ni modifica SQL Server.

## Conectar la base real

El programa consulta exclusivamente dbo.Mensajeria de DashboardOperaciones. Requiere los nombres finales MessageID y TradeID. No crea ni modifica tablas.

1. Habilitar TCP/IP para MSSQLSERVER en SQL Server Configuration Manager. Configurar el puerto TCP real (por ejemplo 1433) y reiniciar el servicio si se cambió la configuración. SSMS puede conectarse por otro protocolo aunque JDBC todavía no tenga acceso.
2. Autenticación Windows: descargar el paquete JDBC oficial de Microsoft de la misma versión que el driver Maven y localizar su carpeta auth/x64. La DLL mssql-jdbc_auth debe coincidir con el driver y la arquitectura de Java. Ver la versión efectiva en .tools/repository/com/microsoft/sqlserver/mssql-jdbc.
3. Ejecutar con el directorio real de la DLL:

    .\iniciar.ps1 -Modo sqlserver -AuthDllDirectorio 'C:\ruta\jdbc\auth\x64'

Conexión predeterminada: localhost:1433, DashboardOperaciones, autenticación Windows. Para otro puerto o autenticación SQL usa variables de entorno de la sesión (no guardes contraseñas en archivos):

    $env:SQLSERVER_URL = 'jdbc:sqlserver://localhost:1433;databaseName=DashboardOperaciones;encrypt=true;trustServerCertificate=true;loginTimeout=5'
    $env:SQLSERVER_USER = 'usuario_lector'
    $env:SQLSERVER_PASSWORD = Read-Host 'Contraseña' -MaskInput
    .\iniciar.ps1 -Modo sqlserver

Read-Host -MaskInput requiere PowerShell 7. En Windows PowerShell 5 usa autenticación Windows. El login SQL debe existir y tener permiso SELECT; este proyecto no modifica la autenticación del servidor.

trustServerCertificate=true se incluye para desarrollo local. En despliegue usa un certificado confiable y validación de certificado. La aplicación escucha solamente en 127.0.0.1.

Referencia oficial: https://learn.microsoft.com/en-us/sql/connect/jdbc/building-the-connection-url

## Indicadores y alcance

- Mensajes recibidos y referencias TradeID únicas.
- Dos patas recibidas: exactamente dos mensajes con bancos emisor/receptor recíprocos. No valida montos ni monedas, no confirma matching.
- Esperando contraparte: referencias con un mensaje.
- Referencias con mensajes adicionales o bancos no recíprocos se indican aparte.
- Todos los indicadores, cobertura y exportación se calculan sobre los mensajes filtrados. Filtrar por banco o fecha puede excluir una pata.
- Gráfico por hora del día (acumula las fechas seleccionadas).
- No se suman nominales de distintas monedas ni las dos patas de un trade.
- Filtros de fecha, paginación y CSV se ejecutan en el navegador. Se admite hasta 10.000 mensajes; ante un volumen mayor el servicio devuelve error explícito y requiere evolucionar a filtros/paginación SQL.
- EstadoMensaje admite PENDING_MATCH, REJECTED, MATCH y LOADED. Los ejemplos asignan estos estados para demostración; no hay un motor automático de matching ni historial de transiciones.

## Comprobar y compilar

    .\.tools\apache-maven-3.9.9\bin\mvn.cmd '-Dmaven.repo.local=.tools/repository' test package

El JAR ejecutable se genera en target/dashboard-0.0.1-SNAPSHOT.jar. La conexión real debe verificarse en el equipo donde funciona SQL Server; nunca hay cambio silencioso de SQL a datos demo.

La pantalla se titula Dashboard Diario Operacional. Los filtros superiores son Desde y Hasta. El pie indica SQL Server conectado solo después de una consulta exitosa, modo de ejemplo o fallo de consulta; se actualiza al abrir la página o pulsar Actualizar datos y muestra la hora de la última consulta correcta.

## Estados de mensajes

Ejecutar sql/002_estados_mensajeria.sql en SSMS sobre DashboardOperaciones. Migra RECIBIDO a PENDING_MATCH, establece el valor predeterminado y restringe los estados permitidos. Agrega ocho mensajes ficticios sin duplicar MessageID al repetirlo. Fechas de ejemplo: 2026-11-02.

PENDING_MATCH: pendiente de matching; REJECTED: rechazado; MATCH: matcheado; LOADED: ingresado al sistema. El dashboard distingue cada estado por texto y color. Los indicadores de patas siguen contando recepción, independientemente del estado.

## Cajas superiores

Mensajes Recibidos: total de mensajes filtrados por fecha. Mensajes Rechazados: REJECTED. Mensajes Esperando Contraparte: PENDING_MATCH (según el estado registrado, no deducido del número de patas). Mensajes Compensados: MATCH, como equivalencia inicial de esta pantalla. LOADED solo se incluye en recibidos. Las cuatro cifras no son categorías que deban sumar el total: recibidos incluye todos los estados. El gráfico de torta muestra combinaciones de TipoMensaje y EstadoMensaje sobre el total de mensajes filtrados.

El gráfico de torta agrupa por TipoMensaje y EstadoMensaje. Cada porción representa el porcentaje de esa combinación sobre todos los mensajes del período. La leyenda muestra cantidad y porcentaje (redondeado a un decimal); sin mensajes se muestra un círculo neutro y una explicación.

## Trades

Ejecutar sql/003_trades.sql: crea dbo.Trades y 20 ejemplos (sin duplicar TradeID al repetir). BancoEmisor BCHI/BKSA/CRED y contrapartes BECH/BICH/BSCH son ejemplos, no se limita el futuro catálogo de 12 bancos. Servicio usa NDF como valor ficticio. Nocional en la primera moneda del par; tipo de cambio en CLP por unidad de esa moneda. Fechas Inicio <= Fixing <= Matured. Estado: Matured, Cleared, REJECTED_HRC.

FechaHoraIngreso es la fecha/hora local operacional de Chile. Los 20 datos se anclan al día de la primera ejecución: 16 hoy y 4 ayer. Una reejecución no mueve fechas ni reinserta datos. Se incluyen estados no Cleared e ingresos previos para comprobar exclusiones.

GET /api/trades/cleared-hoy calcula hoy en America/Santiago y cuenta filas con Estado Cleared y FechaHoraIngreso entre medianoche de hoy (inclusive) y la de mañana (exclusive), agrupando por BancoEmisor. El gráfico muestra este indicador fijo de hoy, independiente de los filtros de mensajes. Bancos sin operaciones hoy aparecen en cero. Se actualiza al cargar y pulsar Actualizar datos. No se suman nocionales ni se cuenta la contraparte como un segundo trade.

Trades y Mensajeria siguen sin relación automática: no se inventa una correspondencia entre referencias de ejemplo ni un motor de matching.

El gráfico Cleared usa eje X banco emisor y eje Y SUM(ABS(Nocional)), agrupado por moneda. El selector local alterna USD/CLP (nocional USD) y CLF/CLP (nocional CLF), evitando sumar unidades incompatibles. Se mantienen hoy y Cleared como filtros del endpoint.

Barras Cleared: CLF dorado y USD azul, agrupadas por banco y con eje numérico común sin conversión; los importes conservan su unidad, no se suman entre monedas. Se eliminó el selector. Quién con quién agrupa todos los trades ingresados hoy por banco, contraparte y moneda, sumando ABS(Nocional). HRC cuenta REJECTED_HRC ingresados hoy por contraparte. Los tres cuadros se actualizan juntos desde /api/trades/cleared-hoy.

Presentación actual: dos cuadros Cleared independientes USD (azul) y CLF (dorado), cada uno con su propia escala Y y totales. Quién con quién también se separa en dos tablas por moneda. Ambos usan las mismas consultas existentes y conservan el alcance de ingresos de hoy.

Nocionales con signo: ejecutar sql/004_nocional_con_signo.sql. Quita la restricción de nocional positivo y conserva TipoCambio > 0, sin cambiar importes existentes. Cada gráfico de moneda muestra bruto SUM(ABS(Nocional)) y neto SUM(Nocional), con línea cero y eje negativo cuando corresponde. Los ejemplos en memoria incluyen signos mixtos; los registros SQL existentes conservan sus valores. Quién con quién conserva el nocional bruto.
