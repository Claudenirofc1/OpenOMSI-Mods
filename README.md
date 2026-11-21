# OpenOMSI Mods — HOF automático, câmeras das portas e dashcam (projeto independente, NÃO oficial)

Pacote de **mods opcionais** para o [openOMSI](https://github.com/openOMSI-org/openOMSI) com um instalador de janelas e caixas de seleção: você marca só o que quer. Sem linha de comando, sem mexer em arquivos à mão.

> **Aviso:** este projeto não tem relação com a organização openOMSI nem com o autor do jogo. O nome openOMSI é usado só para dizer a que jogo isto se aplica. A versão atual é um **pré-release**: passou nos testes automáticos, mas ainda **não foi validada dentro do jogo em vários PCs**. Veja [Estado de validação](#estado-de-validação-honesto).

## Baixar

**[⬇ Baixar o ZIP (v0.3.54)](https://github.com/Claudenirofc1/OpenOMSI-Mods/releases/download/v0.3.54-hofauto/openOMSI-HOF-Auto-v0.3.54.zip)** · [página da release](https://github.com/Claudenirofc1/OpenOMSI-Mods/releases/tag/v0.3.54-hofauto)

Funciona com o **openOMSI v0.3.54** (a versão é conferida pelo instalador; se for outra, ele **não altera nada**).

## Instalar em 6 passos (vale para qualquer PC)

**O que você precisa:** Windows 10 ou 11 e o openOMSI v0.3.54 já instalado, em **qualquer pasta ou disco**. Não precisa instalar nada além disso (o PowerShell que o instalador usa já vem no Windows).

1. **Baixe** o ZIP pelo botão acima.
2. **Extraia o ZIP inteiro** para uma pasta qualquer (botão direito → *Extrair tudo*). Não rode de dentro do ZIP.
3. **Feche o jogo e o launcher.**
4. Dê duplo clique em **`Instalar OpenOMSI HOF-Auto.exe`**. Se o Windows mostrar *"O Windows protegeu o computador"* (o programa não tem assinatura digital paga), clique em **Mais informações → Executar assim mesmo**. Se o antivírus reclamar, é pelo mesmo motivo: o arquivo é compilado no GitHub a partir do código deste repositório (veja a [origem do código](#código-fonte-e-licença)).
5. Na janela, **aponte o `openomsi.exe` do SEU jogo** (o instalador tenta achar sozinho e pergunta se a pasta encontrada é a certa). Ele usa a pasta desse arquivo e só troca 4 programas do jogo, com backup. Marque os mods que quer e confirme.
6. **Abra o jogo normalmente.** Pronto.

**Se o jogo estiver em `Arquivos de Programas`** (ou outra pasta protegida), o instalador avisa que não tem permissão e não altera nada: feche e abra de novo com **botão direito → Executar como administrador**.

**Para voltar ao original:** abra o instalador de novo e use *Restaurar/Desinstalar*, ou dê duplo clique em `Desinstalar.cmd`.

### Dashcam: precisa do `ffmpeg.exe`

A dashcam grava MP4 usando o ffmpeg, que **não vem junto** (é um programa de terceiros). O jogo procura o `ffmpeg.exe`, nesta ordem:

- na pasta do jogo (ao lado do `openomsi.exe`);
- em `%USERPROFILE%\.openomsi\bin`;
- no `PATH` do Windows (por exemplo, depois de `winget install Gyan.FFmpeg` num terminal) ou na variável `OPENOMSI_FFMPEG`.

Sem o ffmpeg, só a dashcam fica indisponível; o resto funciona.

## Mods

| Mod | O que faz |
|---|---|
| **HOF automático** | Abrir o jogo → mapa → ônibus → linha/tour → jogar, sem escolher o HOF à mão quando o jogo consegue provar qual é o correto. |
| **Câmeras das portas** | Cadastre câmeras por ônibus, no ponto de vista que quiser. Ao abrir uma porta ligada a câmeras, aparece **um popup** só com as câmeras **daquela porta** (a porta 2 mostra só as câmeras da 2); some quando elas fecham. Gatilho opcional: abrir qualquer porta mostra todas. |
| **Dashcam** | Câmera fixa no ônibus que grava a viagem em **MP4** (visão limpa ou estilo câmera de segurança com relógio e nome). O painel diz **para onde ela está olhando** e mostra `● REC mm:ss` enquanto grava. |
| **IAs travadas** (`ai_unstick`) | Recupera trânsito de IA parado de vez, por cima do que o jogo já faz: só age depois de bastante tempo sem progresso e sem motivo legítimo (semáforo, parada, pedestres, o seu veículo…), confirma em verificações seguidas, remove **só o carro causador**, **só fora da vista de qualquer jogador**, nunca ônibus de linha. Registra tudo no log do jogo (`ai-unstick:`). |

## Como usar no jogo

**Câmeras das portas**
1. Toque em **`Alt`** → vá à **página 3** → **Câmeras das portas**.
2. Olhe (câmera livre) para onde quer a câmera e aperte **Adicionar uma câmera aqui**.
3. Marque as **portas** que abrem essa câmera. Dá para ajustar campo de visão, espelhar e remover.
4. Repita para outras câmeras/portas. Ao abrir a porta, o popup mostra só as câmeras dela.
5. **Ajuste fino** (no mesmo painel): escolha o **passo fino** (1× / 0,25× / 0,10× / 0,05×) — ele reduz a velocidade da câmera livre e o tamanho de cada toque nos botões **X± Y± Z±** (posição no ônibus) e **Giro/Inclinação/Rolagem ±**. **Nivelar o horizonte** mantém o horizonte reto mesmo com o ônibus inclinado em rampa (a câmera mantém a direção configurada).
6. **Popups**: botão **Mover / redimensionar os popups** (ou `Ctrl+Alt+P`): arraste com o mouse e use a roda para o tamanho; tudo fica salvo por ônibus e **não altera o enquadramento da câmera**.

**Onde ficam salvas (e a limitação honesta):** as câmeras ficam salvas **por modelo de ônibus** (não dependem de mapa, linha, escala nem de reiniciar o jogo/PC) em `%USERPROFILE%\.openomsi\door_cams.cfg`, com cópia de segurança `door_cams.cfg.bak`. O jogo **não tem identidade permanente por veículo**: o único identificador é o **número de frota** escolhido ao iniciar. Por isso, a opção **“Só este veículo”** (aparece se o veículo tem número de frota) guarda um perfil por *modelo + número*; sem número de frota, o perfil é do modelo (todos os ônibus daquele modelo compartilham). Câmeras criadas por versões anteriores são migradas automaticamente, sem apagar nada.

**Dashcam**
1. **`Alt` → página 3 → Dashcam → Posicionar a câmera aqui.** Ela fica fixa no ônibus, como uma câmera instalada; o painel diz para onde ela foca.
2. Quando quiser, volte ao mesmo painel e toque em **Iniciar gravação**; para encerrar, **Parar gravação** (ou, se esquecer, o vídeo continua tocável).
3. Vídeos em `Vídeos\openOMSI-dashcam`.

**Botões do volante/teclado:** em **Controles**, dê a qualquer botão as ações "Câmeras das portas: …" e "Dashcam: …".

**Launcher:** Ajustes → **Mods** (liga/desliga cada mod e edita as câmeras por ônibus).

**Atalhos de teclado (opcionais):** `Ctrl+K` liga/desliga as câmeras das portas · `Ctrl+Shift+K` cadastra uma câmera na visão atual · `Ctrl+Shift+1..9` liga/desliga a porta N da última câmera · `Ctrl+Alt+K` remove a última · `Ctrl+Alt+Shift+K` gatilho "qualquer porta" · `Ctrl+Alt+P` editor dos popups · `Ctrl+J` inicia/para a dashcam · `Ctrl+Shift+J` posiciona · `Ctrl+Alt+J` troca o visual.

## O que o instalador faz (e não faz)

- Troca **somente 4 executáveis** do jogo (`openomsi.exe`, `openomsi-launcher.exe`, `openomsi-launcher-app.exe`, `omsi-plugin-host32.exe`).
- **Prova a versão** do seu jogo pelos hashes dos executáveis. Se não for uma versão conhecida e compatível, bloqueia e não altera nada.
- Antes de trocar, guarda os originais em backup versionado (`%LOCALAPPDATA%\openOMSI-HOF-Auto\backup\<data-hora>`) e confere cada arquivo por hash. Se algo falhar, restaura sozinho; se a energia cair no meio, desfaz na próxima execução.
- Recusa continuar com o jogo ou o launcher abertos.
- **Não mexe** em mapas, ônibus, HOFs, saves, configurações pessoais, OMSI 2 nem em outros mods. Nenhum conteúdo de terceiros vem neste projeto.
- Guarda uma **cópia do perfil** (escolhas, câmeras, dashcam) em `Documentos\openOMSI-HOF-Auto\perfil`; depois de formatar, instale de novo e ele traz de volta sem sobrescrever nada seu.

Escolhas dos mods ficam em `.openomsi\hofauto-mods.cfg` na pasta do seu usuário (`nome=1` liga, `nome=0` desliga; vale em segundos, sem reiniciar). Variáveis alternativas: `OPENOMSI_HOF_AUTO=off`, `OPENOMSI_DOOR_CAMS=off`, `OPENOMSI_DASHCAM=off`.

## Gerenciador (menu)

O mesmo instalador abre um menu (`Gerenciador.cmd` ou o `.exe`) com:

| Função | O que faz |
|---|---|
| **Instalar** | Escolhe os mods, faz backup versionado e confere hashes. |
| **Atualizar** | Consulta **só as releases deste repositório** (HTTPS), baixa o ZIP da versão compatível com o seu jogo, confere cada arquivo contra o `manifest.json` e instala. Sem release para a sua versão: recusa e avisa. |
| **Reparar** | Diagnostica, **mostra os problemas e a proposta e pede autorização** antes de reinstalar. |
| **Diagnóstico** | Só mostra o estado; não altera nada. |
| **Exportar / Importar perfil** | Leva suas escolhas e câmeras para outra pasta/pendrive e traz de volta depois. |
| **Restaurar** | Devolve os originais de um backup à sua escolha. |

## Quando o jogo oficial se atualiza

Cada release é compilada **a partir da versão oficial correspondente** do openOMSI, com as nossas alterações por cima ([`patches/hof-auto.patch`](patches/hof-auto.patch)). Uma rotina automática confere todo dia se saiu versão oficial nova; se sair, reaplica o patch, roda os testes e publica a release. **Se o patch não aplicar ou um teste falhar, nada é publicado.**

- Se o jogo se atualizar sozinho e sobrescrever os arquivos: o instalador percebe que a versão mudou e **bloqueia** até existir release compatível. Não instale a release de outra versão.
- Sem release para a sua versão: espere a nova ou use o jogo oficial normalmente.

## Estado de validação (honesto)

- **Testes automáticos:** lógica do jogo (portas, dashcam, formatos de arquivo, painéis), do launcher e do gerenciador (Windows PowerShell 5.1 e 7) passam no GitHub Actions.
- **Já visto no jogo (HOF automático):** v0.3.54, em um PC, com 3 ônibus e letreiro/cockpit funcionando.
- **Ainda não validado no jogo real:** painéis do `Alt`, aba Mods do launcher, o `.exe` de instalação, a gravação da dashcam (e o impacto no FPS, que **não foi medido**), botões do volante. A dashcam lê a imagem da GPU a cada quadro e pode custar FPS.
- Outros PCs, versões do Windows, mapas e versões do jogo: **sem confirmação ainda**. Trate como **pronto para teste**, não como 100% funcional, e relate o que encontrar em [Issues](https://github.com/Claudenirofc1/OpenOMSI-Mods/issues) junto com o arquivo de log do jogo e o `log` do instalador (`%LOCALAPPDATA%\openOMSI-HOF-Auto`).

Mais detalhes, atualização e checklist de testes: **[docs/INSTALACAO.md](docs/INSTALACAO.md)**.

## Código-fonte e licença

O openOMSI é licenciado sob **AGPL-3.0**; este projeto mantém a mesma licença ([LICENSE](LICENSE)). O código-fonte correspondente de cada release é: o openOMSI oficial na tag indicada em `ORIGEM-DO-CODIGO.txt` (dentro do ZIP) + o arquivo [`patches/hof-auto.patch`](patches/hof-auto.patch). O `.exe` de instalação é compilado no GitHub a partir de [`tools/Instalar.cs`](tools/Instalar.cs) (só inicia o script `Instalar-HOF-Auto.ps1`, que está em texto aberto no ZIP). OMSI e OMSI 2 são marcas dos seus respectivos donos.
