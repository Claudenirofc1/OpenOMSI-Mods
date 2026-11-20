# openOMSI HOF Auto (projeto independente, NÃO oficial)

Instalador simples que acrescenta ao [openOMSI](https://github.com/openOMSI-org/openOMSI) a **escolha automática do arquivo de garagem (HOF)**: abrir o jogo → escolher mapa → ônibus → linha/tour → jogar, sem escolher HOF à mão quando o jogo consegue provar qual é o correto.

> Este projeto **não é oficial** e não tem relação com a organização openOMSI nem com o autor do openOMSI. O nome openOMSI é usado só para dizer a que jogo isto se aplica.

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

Cada release é compilada **a partir da versão oficial correspondente** do openOMSI, com a nossa alteração aplicada por cima ([`patches/hof-auto.patch`](patches/hof-auto.patch)). Uma rotina automática (GitHub Actions) confere todo dia se saiu uma versão oficial nova; se sair, ela reaplica o patch, roda os testes e publica a release nova. **Se o patch não aplicar ou um teste falhar, nada é publicado**, então o projeto nunca entrega um jogo quebrado de propósito.

- Se o jogo oficial se atualizar e sobrescrever os arquivos: baixe a release da versão nova daqui e rode `Instalar.cmd` de novo (o backup anterior fica guardado).
- Se ainda não houver release para a sua versão do jogo, **não instale** a de outra versão: espere a nova ou use o oficial.

## Estado de validação (honesto)

- Testado no jogo, versão **v0.3.54**, no PC do autor: 3 ônibus diferentes, linhas 15 e 103 do mapa Bolsão V, com letreiro automático e cockpit remoto funcionando.
- **Não** testado: outras linhas e mapas, versões oficiais mais novas, e o instalador deste repositório em outros PCs. O fluxo de build automático (GitHub Actions) ainda não rodou. Trate como **pronto para teste**, não como 100% funcional.
- Para desligar o recurso sem desinstalar: defina a variável de ambiente `OPENOMSI_HOF_AUTO=off` antes de abrir o launcher.

## Código-fonte e licença

O openOMSI é licenciado sob **AGPL-3.0**; este projeto mantém a mesma licença ([LICENSE](LICENSE)). O código-fonte correspondente de cada release é: o openOMSI oficial na tag indicada em `ORIGEM-DO-CODIGO.txt` + o arquivo [`patches/hof-auto.patch`](patches/hof-auto.patch). OMSI e OMSI 2 são marcas dos seus respectivos donos.
