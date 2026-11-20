@echo off
rem OpenOMSI Mod Manager (nao oficial): menu com instalar, atualizar, reparar, diagnostico, exportar e importar perfil.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-HOF-Auto.ps1" -Modo Menu
