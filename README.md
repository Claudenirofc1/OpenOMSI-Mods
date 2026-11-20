# openOMSI HOF Auto (projeto independente, NÃO oficial)

Pacote de **mods opcionais** para o [openOMSI](https://github.com/openOMSI-org/openOMSI), com instalador de caixas de seleção: você marca quais quer.

## Mods

| Mod | O que faz | Teclas |
|---|---|---|
| **HOF automático** | Abrir o jogo → mapa → ônibus → linha/tour → jogar, sem escolher o HOF à mão quando o jogo consegue provar qual é o correto. | — |
| **Câmeras das portas** | Cadastre câmeras por ônibus (na câmera livre, no ponto de vista desejado). Ao abrir uma porta ligada a uma câmera, aparece **um popup** com todas as câmeras do ônibus lado a lado, na ordem do cadastro. Abrir/fechar uma só não muda nada; some quando todas as portas com câmera fecham. Gatilho opcional: abrir qualquer porta. | `Ctrl+K` liga/desliga · `Ctrl+Shift+K` cadastra câmera na visão atual · `Ctrl+Shift+1..9` liga/desliga a porta N da última câmera · `Ctrl+Alt+K` remove a última · `Ctrl+Alt+Shift+K` gatilho "qualquer porta" |
| **Dashcam** | Segunda câmera configurável que grava a viagem inteira em **MP4** (visão limpa por padrão, ou estilo câmera de segurança com relógio e nome). Precisa do `ffmpeg.exe`. | `Ctrl+J` inicia/para · `Ctrl+Shift+J` posiciona na visão atual · `Ctrl+Alt+J` troca o visual |

Os cadastros ficam em `door_cams.cfg` e `dashcam.cfg` (pasta `.openomsi` do seu usuário), por ônibus; os nomes das câmeras ("Door N") podem ser editados nesse arquivo. Vídeos da dashcam: `Vídeos\openOMSI-dashcam`.

### Escolher mods e guardar o perfil

O instalador mostra caixas para cada mod e grava a escolha em `.openomsi\hofauto-mods.cfg` (`nome=1`/`0`; vale na hora, sem reiniciar). Uma **cópia do perfil** (escolhas, câmeras das portas, dashcam, retrovisores) é salva em `Documentos\openOMSI-HOF-Auto\perfil`. Depois de desinstalar ou formatar o PC: instale de novo (o perfil é trazido de volta sozinho, sem sobrescrever nada seu) ou use `Restaurar-Perfil.cmd`.

> Este projeto **não é oficial** e não tem relação com a organização openOMSI nem com o autor do openOMSI. O nome openOMSI é usado só para dizer a que jogo isto se aplica.


## OpenOMSI Mod Manager (`Gerenciador.cmd`)

Duplo clique em `Gerenciador.cmd` abre o menu. É o mesmo instalador, com mais funções:

| Função | O que faz |
|---|---|
| **Instalar** | Escolhe os mods (caixas), faz backup versionado dos 4 executáveis e confere hashes. |
| **Atualizar** | Lê a versão do seu jogo, consulta **só as releases deste repositório** (HTTPS), baixa o ZIP da versão compatível, confere o hash de cada arquivo contra o `manifest.json` e instala. Sem release para a sua versão do jogo: recusa e avisa. |
| **Reparar** | Diagnostica (versão, hashes, mods, ffmpeg, backups), **mostra os problemas e a proposta e pede autorização** antes de reinstalar. |
| **Diagnóstico** | Só mostra o estado, não altera nada. |
| **Exportar / Importar perfil** | Copia escolhas, câmeras das portas, dashcam e retrovisores para a pasta que você escolher (ideal: pendrive/outra unidade) e traz de volta depois de formatar. |
| **Restaurar** | `Desinstalar.cmd` devolve os originais do backup mais recente. |

Segurança: recusa instalar se a versão do jogo for incompatível com o pacote ou se um arquivo não bater com o manifesto; recusa mexer com o jogo aberto; uma instalação interrompida é desfeita sozinha na próxima execução; as operações locais funcionam offline. O gerenciador **não** modifica nem reverte a instalação oficial do jogo: ele só troca os 4 executáveis (com backup).

Manifesto (`manifest.json`, gerado pela release): módulos e versões, versões compatíveis do openOMSI, hash de cada arquivo, dependências (ex.: `ffmpeg` para a dashcam), como atualizar e restaurar. Um novo módulo entra acrescentando uma entrada ali e o patch correspondente; o gerenciador não precisa ser refeito.

> Estado: a lógica do gerenciador foi escrita e revisada, mas **ainda não foi executada** (sem PowerShell no ambiente de desenvolvimento). Trate como pronto para teste no seu Windows.

## Como instalar (sem comandos)

1. Abra a página **[Releases](../../releases)** e baixe o `openOMSI-HOF-Auto-vX.Y.Z.zip` mais novo.
2. **Extraia o ZIP inteiro** (botão direito → Extrair tudo).
3. Feche o jogo e o launcher, e dê **duplo clique em `Instalar.cmd`**.
4. Confirme a pasta do jogo quando a janela perguntar. Pronto: abra o jogo normalmente.

**Para voltar ao original:** duplo clique em `Desinstalar.cmd`.

## O que o instalador faz (e não faz)

- Troca **somente 4 executáveis** (`openomsi.exe`, `openomsi-launcher.exe`, `openomsi-launcher-app.exe`, `omsi-plugin-host32.exe`).
- Antes, guarda os originais em `%LOCALAPPDATA%\openOMSI-HOF-Auto\backup\` e confere cada arquivo por hash. Se algo falhar, restaura os originais sozinho.
- Recusa continuar se o jogo ou o launcher estiver aberto.
- **Não mexe** em mapas, ônibus, HOFs, configurações, OMSI 2 nem em outros mods. Não vem nenhum conteúdo de terceiros neste projeto.

## Como as atualizações do jogo são tratadas

Cada release é compilada **a partir da versão oficial correspondente** do openOMSI, com as nossas alterações aplicadas por cima ([`patches/hof-auto.patch`](patches/hof-auto.patch)). Uma rotina automática (GitHub Actions) confere todo dia se saiu uma versão oficial nova; se sair, ela reaplica o patch, roda os testes e publica a release nova. **Se o patch não aplicar ou um teste falhar, nada é publicado**, então o projeto nunca entrega um jogo quebrado de propósito.

- Se o jogo oficial se atualizar e sobrescrever os arquivos: baixe a release da versão nova daqui e rode `Instalar.cmd` de novo (o backup anterior fica guardado).
- Se ainda não houver release para a sua versão do jogo, **não instale** a de outra versão: espere a nova ou use o oficial.

## Estado de validação (honesto)

- Testado no jogo, versão **v0.3.54**, no PC do autor: 3 ônibus diferentes, linhas 15 e 103 do mapa Bolsão V, com letreiro automático e cockpit remoto funcionando.
- **Não** testado: outras linhas e mapas, versões oficiais mais novas, e o instalador deste repositório em outros PCs. O fluxo de build automático (GitHub Actions) ainda não rodou. Trate como **pronto para teste**, não como 100% funcional.
- **Câmeras das portas e dashcam: recém-implementadas, testadas só por testes automáticos; ainda não confirmadas no jogo.** A dashcam lê a imagem da GPU a cada quadro e pode custar FPS; o texto do estilo câmera de segurança usa a fonte `arial.ttf` do Windows (não testado).
- Para desligar um mod sem desinstalar: caixa do instalador, ou `nome=0` em `hofauto-mods.cfg`, ou a variável `OPENOMSI_HOF_AUTO=off` (HOF) / `OPENOMSI_DASHCAM=off` / `OPENOMSI_DOOR_CAMS=off`.

## Código-fonte e licença

O openOMSI é licenciado sob **AGPL-3.0**; este projeto mantém a mesma licença ([LICENSE](LICENSE)). O código-fonte correspondente de cada release é: o openOMSI oficial na tag indicada em `ORIGEM-DO-CODIGO.txt` + o arquivo [`patches/hof-auto.patch`](patches/hof-auto.patch). OMSI e OMSI 2 são marcas dos seus respectivos donos.
