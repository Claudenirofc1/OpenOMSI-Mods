@echo off
rem Duplo clique: volta os executaveis ORIGINAIS do jogo (usa o backup feito na instalacao).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-HOF-Auto.ps1" -Desinstalar
