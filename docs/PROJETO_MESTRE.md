# PROJETO MESTRE — OpenOMSI Mods / Mod Manager

Referência única para as próximas sessões (Claude e Codex). Atualize ao concluir cada etapa. Só entra aqui o que foi **verificado**; o que não foi executado fica como pendente.

## Regras permanentes (decididas pelo usuário)
- Não executar o OpenOMSI na instalação principal pela IA; o usuário instala e testa. Não alterar configurações pessoais (G29 / `Inputs\gamectrler.cfg`), não apagar arquivos, não substituir executáveis oficiais sem backup, não publicar instável como estável.
- Câmeras: **rigidamente presas à carroceria**; **sem nivelar horizonte** e **sem roll manual** (decisão de 2026-11-22; o campo `roll`/`level` do arquivo é mantido só por compatibilidade e é ignorado).
- Escopo fechado: sem novas funções fora das ordens.
- Disco D: como unidade de trabalho do usuário (código, backups, vídeos). A IA trabalha numa área de nuvem própria e entrega via GitHub/ZIP; ver "Limite de ambiente".

## Limite de ambiente (honesto)
A IA roda numa máquina Linux na nuvem; não consegue criar pastas/compilar em `D:\` do PC do usuário nem rodar o jogo/janelas do Windows. Por isso: o código vive no GitHub (`Claudenirofc1/OpenOMSI-Mods`), a compilação é feita no GitHub Actions (Windows) e o usuário instala. O jogo/gerenciador usa D: para o que roda no PC dele: vídeos da dashcam (ver abaixo), backups (`D:\Backups\OpenOMSI-Mods`, a configurar no gerenciador).

## Estado (verificado)
| Item | Estado | Evidência |
|---|---|---|
| Patch 0.3.55 aplica limpo na tag oficial | OK | `git apply --check` na tag `v0.3.55` |
| Release `v0.3.55-hofauto` (pré-release) | Publicada, build `730b656` | ZIP sha256 `c1b77ed7…`, manifesto conferido |
| Câmeras das portas (cadastro, render, portas) | Funcional segundo o usuário (teste real no 0.3.55) | relato do usuário |
| Persistência por modelo/veículo, migração, backup `.bak`, salvamento atômico | Implementado + testes automáticos | omsi-cfg 96, omsi-app 599 |
| Popups arrastáveis/redimensionáveis (por câmera) | Implementado + testes de lógica; **sem teste visual real** | testes unitários |
| Passos finos / posição / direção | Implementado; sem teste real | idem |
| Dashcam | **Causa-raiz corrigida em código** (textura sem `COPY_SRC` → `add_capture_texture`); **MP4 real NÃO validado** | pendente de teste no jogo |
| Gerenciador (PowerShell + starter .exe) | Testes automáticos Win PS 5.1/7 OK; **não é o app gráfico final** | CI |

## Pendências reais (ordem)
1. **Janela única inteligente** (esq/dir/ambas, grade no mesmo lado) — ainda são popups por câmera.
2. **Editor compacto** (lista + editor individual, preview ao vivo, salvar/cancelar/desfazer/próxima, lado e carroceria por câmera).
3. **Articulados**: vincular cada câmera ao segmento (frente/trás) usando a transformação 3D do segmento — hoje todas seguem a carroceria dianteira.
4. **Lado real da porta** a partir das variáveis/scripts do ônibus (hoje: só nº da porta).
5. **Dashcam**: validar MP4 real no jogo (+ seguir segmento escolhido; pasta de saída configurável por `OPENOMSI_DASHCAM_DIR` ou `~/.openomsi/dashcam-dir.txt`).
6. **Mod Manager gráfico** único (.exe, sem CMD) com estados reais por módulo.
7. HOF automático: manter se útil (decisão documentada); trânsito: só diagnóstico por enquanto; multiplayer: sem ambiente de teste.

## Decisões
- Identidade do veículo: o jogo só oferece o número de frota (escolhido ao iniciar). Perfil por modelo; perfil por veículo opcional (`modelo#número`).
- Formato `door_cams.cfg` compatível com versões anteriores (campos extras no fim da linha `cam=`).

## Registro por agente
- Claude: câmeras (persistência, popups, ajuste fino), instalador/gerenciador, releases `v0.3.54/55-hofauto`, correção da causa da dashcam.
- Codex: investigação da dashcam/testes — **resultados não vistos por Claude nesta sessão** (não estão no repositório `main`); integrar quando publicados em branch.
