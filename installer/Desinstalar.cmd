@echo off
rem Volta aos arquivos OFICIAIS do jogo (backup oficial mais recente). Para escolher outro backup: Gerenciador.cmd > Restaurar.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-HOF-Auto.ps1" -Desinstalar
