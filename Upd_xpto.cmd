@echo off
regedit /s rmv_vdd.reg
REM superimage - v3.7
REM superimage
set path=%path%;%windir%\system32;%windir%;%windir%\system32\xptoupd

REM checar instancia - existencia de outro processo ja rodando
pv cmd.exe -l>ps.tmp
findstr /I "Upd_xpto.cmd" ps.tmp>ps2.tmp
wc ps2.tmp>run.tmp
for /F "tokens=8" %%a in (run.tmp) do set num_linha=%%a
if %num_linha% GEQ 3 exit

REM Apaga Compartilhamento,Arquivos da Atualizacao Anterior(Pasta DADOS) e inicia
REM o servico mensageiro
net share dados /delete
net start messenger
if exist "dados" limp_dir /y dados

REM - Inicializa Variaveis
set sto=00000000
set macadress=000000000000
set ip=0.0.0.0
set ok_xpto=0
set ok_xpto=0
set ok_bp=0
set dl_ok=0
set srv_upd=srvnumber0167
set tempo=300

REM - Apaga Arquivos Temporarios e de Logs
if exist "*.tmp" del *.tmp
if exist "*.sra" del *.sra

REM - Prepara Tempo de Inicializacao do Script Aleatorio(1000 Segundos) para Maquinas Clientes
random 1 1000>tempo.tmp
for /F "tokens=1" %%a in (tempo.tmp) do set tempo=%%a
sleep %tempo%

REM - Testa Servico Resolucao de Nome(DNS)
:tst_dns
ping %srv_upd%
if not %errorlevel% == 0 goto erro_dns
goto tst_png

Rem - Teste de Conectivivade(20 Tentativas) entre o Servidor de Atualizacao(srvnumber0167 e a Maquina Cliente Local
:tst_png
ping %srv_upd% -n 20 | find "TTL"
if not %errorlevel% == 0 goto erro_png
goto tst_usr

REM - Verifica Existencia da conta(profile) xpto
:tst_usr
set bp_usr=1
if not exist "%systemdrive%\Documents and Settings\xpto\ntuser.dat" set bp_usr=0
goto tst_upd

REM - Verifica Existencia de Atualizacao
:tst_upd
if not exist "\\%srv_upd%\superimageVirtual\bck\update.id" goto erro_upd
goto v_cad

REM - Verifica Cadastro da Maquina Cliente Local no Banco de Dados de Atualizacao
:v_cad
find /I "%computername%" \\%srv_upd%\superimageVirtual\bck\bd.txt>bdlocal.tmp
if not %errorlevel% == 0 goto erro_cad
goto v_pdl

REM - Verifica Existencia de PDL(Ponto de Distribuicao Local) na Agencia
:v_pdl
for /F "tokens=1 delims=_" %%b in (bdlocal.tmp) do set sto=%%b
dir /b %sto%* \\srvnumber0167\logs\pdl\%sto%*>pdl_id.tmp
if %errorlevel% == 0 goto no_pdl
echo >ok_pdl.sra
goto gr_pdl

REM - Maquina Local se Cadastra como PDL
:gr_pdl
for /F "tokens=1" %%c in (bdlocal.tmp) do set id_pdl=%%c
echo >\\srvnumber0167\logs\pdl\%id_pdl%
call DL_Srv
goto sair

REM - Detecta PDL
:no_pdl
for /F "tokens=3 delims=_" %%d in (pdl_id.tmp) do set pdl_id=%%d
if /I "%pdl_id%" == "%computername%" call DL_SRV
if /I not "%pdl_id%" == "%computername%" call DL_PDL
echo >no_pdl.sra
goto sair

REM - Nao Existencia de Atualizacao - Desligamento Automatico
:erro_upd
echo >no_upd.sra
goto sair

REM - Maquina Nao Cadastrada para Fazer Atualizacao - Desligamento Automatico
:erro_cad
echo >erro_cad.sra
goto sair

REM - Problema na resolução de nome(DNS)
:erro_dns
echo >erro_dns.sra
set srv_upd=10.8.32.58
goto tst_png

REM - Erro na Conexao de Rede(TIMEOUT)
:erro_png
echo >erro_png.sra
goto sair

REM - Finalizacao do Programa e Geracao de Logs de Atualizacao
:sair
getmac>mac.tmp
strep mac.tmp mactmp.tmp
for /F "tokens=3" %%e in (mactmp.tmp) do set macadress=%%e
getip %computername%>ip.tmp
for /F "tokens=1" %%f in (ip.tmp) do set ip=%%f
set sto=00000000
for /F "tokens=1 delims=_" %%g in (bdlocal.tmp) do set sto=%%g
if not "%computername%" == "" echo >\\%srv_upd%\logs\%sto%_%macadress%_%computername%_%ip%_%dl_ok%_%ok_bp%_%ok_xpto%_%ok_xpto%
exit


