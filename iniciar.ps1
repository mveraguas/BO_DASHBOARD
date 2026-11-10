param([ValidateSet('demo','sqlserver')][string]$Modo = 'demo', [string]$AuthDllDirectorio = '')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$maven = Join-Path $PSScriptRoot '.tools/apache-maven-3.9.9/bin/mvn.cmd'
if (!(Test-Path $maven)) { throw 'No se encuentra Maven local en .tools. Instala Maven 3.9.9 o restaura esta carpeta.' }
& $maven '-Dmaven.repo.local=.tools/repository' -q package
if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación.' }
$env:DASHBOARD_MODE = $Modo
if ($AuthDllDirectorio) {
    & java "-Djava.library.path=$AuthDllDirectorio" -jar target/dashboard-0.0.1-SNAPSHOT.jar
} else {
    & java -jar target/dashboard-0.0.1-SNAPSHOT.jar
}
