# HANDOFF PARA O CODEX (somente pendências técnicas reais)

Base: branch `main` de `Claudenirofc1/OpenOMSI-Mods`, patch `patches/hof-auto-0.3.55.patch` (sobre a tag oficial `v0.3.55` de openOMSI-org/openOMSI). Trabalhe em branch própria (`codex/...`), não sobrescreva `main`. Registre o resultado em `docs/RETORNO_CODEX.md`.

## 1. Lado real da porta (gatilhos)
- Esperado: descobrir, pelos arquivos/variáveis do `.bus` (scripts de porta, `door_keys` em `crates/omsi-app/src/player.rs`), se cada grupo de porta é esquerda/direita, e preencher `DoorCam.side` automaticamente quando houver evidência confiável.
- Observado: nenhum lado é detectado; o jogador escolhe (`cycle_side` em `crates/omsi-app/src/door_cams.rs`).
- Critério: dado um `.bus` com seletor de lado, o lado correto é sugerido; sem evidência, continua manual. Teste unitário com um `.bus` de exemplo.

## 2. Dashcam presa ao segmento
- Esperado: a dashcam seguir a carroceria dianteira ou traseira escolhida (como `segment_frame` faz para as câmeras das portas).
- Observado: `crates/omsi-app/src/dashcam.rs::camera` usa só `p.vehicle.camera_world_full`.
- Critério: campo de segmento por ônibus em `dashcam.cfg` (compatível com o formato atual) e teste unitário.

## 3. Validação real da dashcam (depende do PC do usuário)
- Correção aplicada: `Renderer::add_capture_texture` (COPY_SRC) em `crates/omsi-render/src/resources/textures.rs`. Não há MP4 validado.
- Critério: MP4 reproduzível gravado em `D:\Videos\OpenOMSI-Dashcam`; se falhar, capturar a mensagem exibida e o log.

## 4. Mod Manager em aplicativo único
- Hoje: `installer/Instalar-HOF-Auto.ps1` (WinForms) + starter C#. Esperado: janela única com cartões por módulo e estado real (Funcional / Pendente de teste / Desativado / Incompatível / Erro), sem CMD visível, mantendo os testes `tests/Test-Manager.ps1`.
- Critério: instalar, atualizar, reparar, backup, restaurar e desinstalar pela janela; testes do CI continuam passando.

## Comando completo para o Codex
Leia `docs/PROJETO_MESTRE.md` e `docs/HANDOFF_CODEX.md` no repositório Claudenirofc1/OpenOMSI-Mods (branch main). Em uma branch `codex/pendencias`, resolva SOMENTE os itens 1, 2 e 4 do HANDOFF (o item 3 depende do PC do usuário), sem alterar o que já funciona (câmeras das portas, persistência, G29, HOF). Rode `cargo test --ignore-rust-version -p omsi-cfg -p omsi-app -p omsi-launcher-api` sobre a tag v0.3.55 com o patch aplicado e os testes do gerenciador. Gere o patch atualizado e escreva `docs/RETORNO_CODEX.md` com commits, arquivos, testes e limitações. Não publique release.
