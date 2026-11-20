@echo off
rem Traz de volta suas escolhas e cameras salvas (depois de formatar o PC ou reinstalar o jogo).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-HOF-Auto.ps1" -SoPerfil
