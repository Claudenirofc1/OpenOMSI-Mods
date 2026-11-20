@echo off
rem Duplo clique: instala o openOMSI HOF Auto (nao oficial) na sua pasta do jogo.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-HOF-Auto.ps1"
