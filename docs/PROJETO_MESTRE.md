# PROJETO MESTRE — OpenOMSI Mods / Mod Manager

Referência única para as próximas sessões (Claude e Codex). Atualize ao concluir cada etapa. Só entra aqui o que foi **verificado**; o que não foi executado fica como pendente.

## Regras permanentes (decididas pelo usuário)
- Não executar o OpenOMSI na instalação principal pela IA; o usuário instala e testa. Não alterar configurações pessoais (G29 / `Inputs\gamectrler.cfg`), não apagar arquivos, não substituir executáveis oficiais sem backup, não publicar instável como estável.
- Câmeras: **rigidamente presas à carroceria**; **sem nivelar horizonte** e **sem roll manual** (decisão de 2026-11-22; o campo `roll`/`level` do arquivo é mantido só por compatibilidade e é ignorado).
- Escopo fechado: sem novas funções fora das ordens.
- Disco D: como unidade de trabalho do usuário (código, backups, vídeos). A IA trabalha numa área de nuvem própria e entrega via GitHub/ZIP; ver "Limite de ambiente".

## Limite de ambiente (honesto)
A IA roda numa máquina Linux na nuvem; não consegue criar pastas/compilar em `D:\` do PC do usuário nem rodar o jogo/janelas do Windows. Por isso: o código vive no GitHub (`Claudenirofc1/OpenOMSI-Mods`), a compilação é feita no GitHub Actions (Windows) e o usuário instala. O jogo/gerenciador usa D: para o que roda no PC dele: vídeos da dashcam (ver abaixo), backups (`D:\Backups\OpenOMSI-Mods`, a configurar no gerenciador).

## Estado (verificado em 2026-11-22)
| Item | Estado | Evidência |
|---|---|---|
| Patch 0.3.55 aplica limpo na tag oficial | OK | `git apply --check` na tag `v0.3.55` |
| Release `v0.3.55-hofauto` (pré-release) | Publicada; build novo em andamento | ver Releases |
| Câmeras das portas (cadastro, render, portas) | Funcional segundo o usuário (0.3.55, teste real) | relato do usuário |
| Persistência por modelo/veículo, migração, `.bak`, gravação atômica | Implementado + testes automáticos | omsi-cfg 96, omsi-app 603 |
| **Janela única** (esq/dir/ambas, grade, arrastar/redimensionar, layout salvo) | Implementado + testes de layout; **sem teste visual real** | testes unitários |
| **Editor compacto** (lista → câmera; preview ao vivo; Salvar/Salvar e próxima/Desfazer/Cancelar) | Implementado; **sem teste visual real** | — |
| **Segmento** (cada câmera presa à carroceria dianteira/traseira pela transformação real) | Implementado (`segment_frame`); **sem teste real em articulado** | — |
| Lado real da porta pelas variáveis do ônibus | **Não implementado**: lado configurado manualmente por câmera | ver pendências |
| Dashcam | Causa-raiz corrigida em código (textura sem `COPY_SRC`); **MP4 real NÃO validado** | pendente de teste no jogo |
| Pasta de vídeos/backups no D: | Gerenciador: menu **Pastas** (padrão D: se existir); jogo lê `dashcam-dir.txt` | testes do gerenciador (Win PS 5.1/7) |
| Mod Manager | WinForms (menu gráfico) + starter .exe sem console; **não é um app único com cartões por módulo** | CI |

## Pendências reais
1. Teste real no jogo de: janela única, editor, articulado (segmento traseiro), dashcam MP4.
2. Detecção automática do lado da porta (exige ler as variáveis/scripts do `.bus`; hoje manual).
3. Dashcam presa ao segmento (ainda usa a carroceria dianteira).
4. Mod Manager em app único com estado real por módulo (Funcional/Pendente de teste/…).
5. Trânsito: apenas diagnóstico; multiplayer: sem ambiente de teste; HOF: preservado (decisão abaixo).

## Decisões
- Identidade do veículo: o jogo só oferece o número de frota (escolhido ao iniciar). Perfil por modelo; perfil por veículo opcional (`modelo#número`).
- Formato `door_cams.cfg` compatível com versões anteriores (campos extras no fim da linha `cam=`).

## Registro por agente
- Claude: câmeras (persistência, janela única, editor compacto, segmentos, ajuste fino), instalador/gerenciador, releases `v0.3.54/55-hofauto`, correção da causa da dashcam.
- Codex: investigação da dashcam/testes — **resultados não vistos por Claude nesta sessão** (não estão no repositório `main`); integrar quando publicados em branch.

## HOF automático (decisão)
Preservado: relatado como funcionando e sem alteração invasiva. Reavaliar só se o jogo oficial passar a escolher o HOF sozinho.
