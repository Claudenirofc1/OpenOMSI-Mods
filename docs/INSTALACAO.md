# Como instalar no jogo (openOMSI v0.3.54)

> Este pacote é **não oficial** e a versão atual é um **pré-release**: os testes automáticos passaram, mas ele **ainda não foi validado dentro do jogo**. Teste primeiro e reporte o que não funcionar.

## O que você precisa
- openOMSI **v0.3.54** já instalado, em **qualquer pasta ou disco** (o instalador pede o `openomsi.exe` do seu jogo).
- Windows 10/11 (o PowerShell usado já vem no Windows). Para a dashcam: `ffmpeg.exe` ao lado do jogo, em `%USERPROFILE%\.openomsi\bin`, no `PATH` ou na variável `OPENOMSI_FFMPEG`.

## Instalar
1. Baixe o ZIP da release: https://github.com/Claudenirofc1/OpenOMSI-Mods/releases/download/v0.3.54-hofauto/openOMSI-HOF-Auto-v0.3.54.zip (ou pela [página da release](https://github.com/Claudenirofc1/OpenOMSI-Mods/releases)).
2. Extraia **a pasta inteira** (não rode de dentro do ZIP).
3. **Feche o jogo e o launcher.**
4. Duplo clique em **`Instalar OpenOMSI HOF-Auto.exe`** (abre uma janela, sem tela preta; o `Gerenciador.cmd` faz o mesmo). Se o Windows avisar "Windows protegeu o computador" (o programa não tem assinatura digital paga), clique em **Mais informações → Executar assim mesmo**. Ele:
   - pede o `openomsi.exe` do seu jogo (tenta achar sozinho e pergunta) e confirma que a pasta aceita gravação (se estiver em `Arquivos de Programas`, abra com botão direito → *Executar como administrador*);
   - confirma que o seu jogo é a versão **provada** (pelos hashes dos executáveis) — se não for, **não altera nada**;
   - mostra o diagnóstico e pede a sua autorização;
   - faz **backup** dos 4 executáveis e das suas configurações em `%LOCALAPPDATA%\openOMSI-HOF-Auto\backup\<data-hora>`;
   - deixa você marcar quais mods quer (HOF automático, câmeras das portas, dashcam, IAs travadas).
5. Abra o jogo normalmente.

Seus ônibus, mapas, HOFs e saves **não são tocados**.

## Usar
- **Câmeras das portas:** no jogo, `Alt` → página 3 → **Câmeras das portas**. Olhe para onde quer a câmera e aperte **Adicionar uma câmera aqui**; marque as **portas** que a abrem. Ao abrir uma porta, o popup mostra **só as câmeras dessa porta**. Ajuste fino (passos 1×/0,25×/0,10×/0,05×, posição, giro/inclinação/rolagem, nivelar horizonte) e mover/redimensionar popups ficam no mesmo painel; tudo é salvo por modelo de ônibus (ou por veículo, se tiver número de frota) e entra no backup/perfil do gerenciador.
- **Dashcam:** `Alt` → página 3 → **Dashcam** → **Posicionar a câmera aqui** (fica fixa no ônibus; o painel diz para onde ela olha) → **Iniciar gravação** / **Parar gravação**. Enquanto grava aparece `● REC mm:ss` na tela. Vídeos: `Vídeos\openOMSI-dashcam`.
- **Botões do volante/teclado:** em **Controles**, dê a qualquer botão as ações "Câmeras das portas: …" e "Dashcam: …".
- **Launcher:** Ajustes → **Mods** (liga/desliga cada mod; ajusta portas, campo de visão, espelho e remoção das câmeras; campo de visão, estilo e nome da dashcam).
- Atalhos antigos continuam: `Ctrl+K…` (portas) e `Ctrl+J…` (dashcam).

## Atualizar / reparar / voltar ao original
- Rode `Gerenciador.cmd` de novo: **Atualizar**, **Reparar**, **Restaurar um backup** (você escolhe a versão), **Desinstalar** (volta aos executáveis oficiais) e **Exportar/Importar perfil** (para outro disco ou depois de formatar).
- Se o jogo for atualizado pelo oficial, o gerenciador **não** reverte nada: ele só diz que a versão não foi provada e **bloqueia** o patch até existir uma release compatível.
- Instalação interrompida (queda de energia etc.): na próxima execução ele se recupera sozinho do backup.

## Checklist do que só você pode validar
1. Gerenciador: instalar, desinstalar, restaurar backup (o jogo abre depois de cada um?).
2. Portas: adicionar 2–3 câmeras, ligar cada uma a uma porta diferente; abrir a porta 2 mostra só as câmeras da 2?
3. Dashcam: posicionar, gravar 1 min, parar, abrir o `.mp4`; o FPS do jogo caiu muito?
4. Botões: dar uma ação a um botão do volante e usar.
5. Launcher › Mods: mudar uma opção e ver no jogo.
6. IAs travadas: procure `ai-unstick:` no log do jogo; desligue com `ai_unstick=0` se estranhar.

Relate problemas junto com o arquivo de log do jogo.
