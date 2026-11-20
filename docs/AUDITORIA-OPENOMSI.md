# Auditoria do openOMSI v0.3.54 (código oficial, somente leitura)

Resumo do que foi lido no código do commit `500a4143` (v0.3.54) para decidir **onde** encaixar cada módulo sem duplicar o que o jogo já tem. O repositório oficial não é alterado: tudo vive em `patches/hof-auto.patch`, aplicado sobre a tag oficial.

| Área | O que o jogo já tem | O que o nosso módulo faz |
|---|---|---|
| Configuração/persistência | `~/.openomsi/settings.cfg`; arquivos `.cfg` ao lado (ex.: `mirror_hud.cfg`); `omsi_cfg::input_in_use` escolhe o arquivo de controles **mais novo** entre a pasta do usuário e a do jogo | `hofauto-mods.cfg` (liga/desliga por módulo, relido a cada 3 s), `door_cams.cfg`, `dashcam.cfg` no mesmo estilo |
| Câmeras/renderização | câmeras de retrovisor (`cameras_reflexion`) renderizadas em texturas por `render_mirrors`; overlays 2D (`scene.overlays`) | câmeras das portas reaproveitam o mesmo pipeline dos retrovisores; popup é um overlay; dashcam usa `render_to_texture` + leitura da GPU |
| Portas | `door_keys`/`door_trigger_open` (mesma lógica da tecla de porta do jogador) | popup segue o estado real das portas |
| HOF | seleção manual no launcher | `hof_auto` escolhe só quando o jogo consegue provar qual HOF é o correto |
| IA do tráfego | `deadlock.rs` (ciclos de espera resolvidos pelas regras), `GIVE_UP_STOOD = 200 s` (carro comum parado), `lateral.rs` (contornar o que está parado), `berths`, `dormant`, `admission` (com *backoff* por trecho) | `unstick.rs` age **depois** de tudo isso, só se o bloqueio persistir (ver README); reutiliza `unseen()` (ninguém vê sumir) e o *backoff* da admissão |
| Semáforos | `TrafficLightController` com fases por luz e ciclo | `max_red()` lê o maior vermelho do mapa para o limite de investigação |
| Falhas/recuperação | carros que desistem após 200 s, ônibus que largam a rota após 40 s esperando trecho | não duplicado; o módulo cobre o que sobra (ônibus de linha **não** são removidos) |

Achados relevantes:

- O jogo **não** tem manobra de ré/esterçar mais para IA presa; este projeto **não** adiciona isso (fora do escopo aprovado): só recupera o fluxo removendo a causadora quando seguro.
- `AiCar::gone` é marcado pelo jogo para carros que desistiram, mas a retirada efetiva depende de outras partes; por isso `ai_unstick` retira pelo caminho oficial `take_off_id`, e só quando `TrafficSim::unseen` garante que ninguém vê.
- Versão do jogo não é legível de forma confiável no `.exe` (o `openomsi.exe` não tem `ProductVersion`; o `openomsi-launcher-app.exe` só é carimbado nas builds de release). Por isso o gerenciador **prova** a versão pelos hashes dos executáveis (`installer/known-hashes.json` + o manifesto do pacote).
