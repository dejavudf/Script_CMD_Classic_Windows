@echo off
:inicio
echo ******** Instalacao do superimage ********
for /F "tokens=1-2" %%b in (ip.txt) do start /min principal.cmd %%b & sleep 50
goto inicio