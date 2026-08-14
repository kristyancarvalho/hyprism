# Hyprism

Hyprism é um shell reproduzível para Arch Linux e Hyprland, construído com Quickshell. A interface principal é uma ilha morfológica centralizada no topo: compacta em repouso, expandida no hover e ampliada verticalmente para aplicativos, papéis de parede, área de transferência, notificações, controles, troca de janelas e energia.

Quickshell implementa toda a interface visível. O projeto não usa Waybar, AGS, Eww, Rofi, Dunst, SwayNC nem Wlogout.

## Instalação no Arch Linux

Revise [packages/pacman.txt](packages/pacman.txt) e [packages/aur.txt](packages/aur.txt), clone o repositório e execute:

```bash
sudo ./install.sh --user "$USER"
```

Para atualizar somente os arquivos depois que as dependências já estiverem instaladas:

```bash
sudo ./install.sh --user "$USER" --no-packages
```

O instalador:

- instala pacotes oficiais e usa `paru` ou `yay` somente quando `packages/aur.txt` contém entradas;
- instala Papirus, Symbols Nerd Font Mono e as ferramentas do Fontconfig a partir dos repositórios oficiais do Arch;
- baixa Google Sans Flex 400, 500 e 600 diretamente do CDN oficial do Google Fonts, em URLs versionadas e verificadas por SHA-256, sem redistribuir binários no repositório;
- instala o Colloid no escopo do usuário a partir de uma revisão upstream fixada e cria a variante dinâmica `Colloid-Hyprism-Dark-Matugen`;
- provisiona Hyprlock, Kvantum para Qt 5/6, `qt5ct`, `qt6ct` e as ferramentas de compilação do tema GTK;
- cria `~/Imagens/Wallpapers` e `~/Imagens/Screenshots` sem apagar conteúdo existente;
- copia os arquivos runtime para `~/.local/share/hyprism`, sem depender do local original do clone;
- cria links para `~/.config/hypr`, `~/.config/quickshell/default`, o alias `~/.config/quickshell/hyprism`, Foot, Kitty, GTK 3/4, Kvantum, Qt 5/6 e a configuração do usuário;
- guarda conflitos em `~/.local/state/hyprism/backups/`;
- verifica `hyprland.lua`, `shell.qml`, `foot.ini` e o tema de fallback do Foot;
- não instala nem ativa um `hyprland.conf` legado.

## Arquitetura

```text
install.sh
  └─ ~/.local/share/hyprism
      ├─ config/hypr/hyprland.lua
      │   └─ modules/autostart.lua
      │       └─ scripts/system/start-shell
      │           └─ qs -c default
      │               └─ shell.qml
      └─ config/quickshell
          ├─ ilha e painéis
          ├─ widgets de data e sistema
          ├─ notificações e OSD
          └─ serviços opcionais resilientes
```

`config/hypr/hyprland.lua` é o ponto de entrada Lua do Hyprland 0.55 ou posterior. Os módulos separam programas, monitores, aparência, entrada, layouts, regras, workspaces, atalhos, ambiente e autostart. Não há configuração Hyprland `.conf` ativa no repositório.

O Quickshell é iniciado uma única vez pelo evento `hyprland.start`. O helper usa o executável canônico `qs`, a configuração nomeada `default`, `--no-duplicate`, uma raiz runtime estável e um locale UTF-8 já disponível no sistema. A alteração de locale fica restrita ao processo do Hyprism. `scripts/system/shell-ipc` centraliza a seleção de instância usada pelo Hyprland, OSD, wallpaper e recuperação. `QS_CONFIG_NAME=default` seleciona a instalação; `HYPRISM_QS_PATH` seleciona um caminho explícito em desenvolvimento. O alias `hyprism` preserva compatibilidade. Recarregar a configuração do Hyprland não acumula processos do shell.

No primeiro boot, a paleta escura embutida mantém a ilha e os widgets utilizáveis mesmo sem arquivos gerados. Ausência de bateria, Wi-Fi, Bluetooth, brilho, GPU, sensores, MPRIS, clima ou histórico de clipboard produz um estado indisponível ou oculto, sem bloquear o `shell.qml`.

Google Sans Flex é a família primária de texto da interface. Symbols Nerd Font Mono é usada somente para a iconografia semântica do shell. Os tamanhos, pesos, alturas, espaçamentos, raios e glifos ficam centralizados em `Design.qml`, e componentes compartilhados mantêm a linha de base e o ritmo vertical da ilha. O sistema visual usa retângulos arredondados de 9 px como forma dominante, com 6 px para elementos pequenos e 12 px para superfícies amplas. Hierarquia tonal, espaçamento e preenchimento de estado substituem contornos repetidos; bordas ficam reservadas ao foco, à seleção, à urgência e à definição externa da ilha.

O índice de aplicativos percorre `XDG_DATA_HOME` e `XDG_DATA_DIRS` uma vez na inicialização, lê ID, `StartupWMClass`, `Exec`, `TryExec`, nome e `Icon` dos arquivos `.desktop` e cria um cache normalizado compartilhado. O Alt+Tab tenta `class`, `initialClass` e app ID contra esses aliases; o campo `Icon` resolvido passa pelo tema Hyprism-Papirus, que herda os aplicativos normais do Papirus-Dark, com fallback para `application-x-executable`. Launcher, Alt+Tab e mídia usam o mesmo cache. Estados do sistema usam exclusivamente o mapa semântico Nerd Font; emoji não é usado como ícone de status.

Um `PanelWindow` transparente de 1 px mantém a zona exclusiva constante composta pela margem superior, pela altura compacta e pelo respiro configurado, sem desenhar fundo, borda ou conteúdo. Janelas tiled e maximizadas começam abaixo dessa faixa. Em cada monitor, um canvas overlay transparente de tamanho fixo contém a única superfície visual da ilha. Launcher, controles, notificações, mídia expandida e Alt+Tab animam essa superfície dentro do canvas sem redimensionar a superfície Wayland, ampliar a zona exclusiva ou reorganizar as janelas.

O workspace ativo de cada monitor fornece o estado real `hasFullscreen`. Nesse estado, somente a ilha persistente, seus widgets e sua reserva daquele monitor são ocultados. Outros monitores continuam normais. Um painel solicitado explicitamente continua autorizado a aparecer sobre fullscreen e mantém a mesma tela alvo.

O Alt+Tab usa os toplevels do Hyprland expostos pelo Quickshell e mantém uma lista MRU atualizada por eventos de foco. Cada entrada guarda o endereço hexadecimal canônico da janela. A primeira troca seleciona a janela focada anteriormente; repetições avançam ou recuam e soltar Alt chama `hl.dsp.focus` com `address:`, inclusive em outro workspace ou monitor. A interface mostra ícone Papirus, nome do aplicativo e título, com fallback intencional quando algum metadado está ausente.

Launcher, papéis de parede, clipboard, redes, Bluetooth, central de controle, notificações, energia, mídia e Alt+Tab aceitam navegação por teclado. `Escape` fecha, `Enter` ativa, setas percorrem listas, grades e controles, e `Tab` mantém a travessia de foco onde não conflita com o alternador de janelas.

Na ilha compacta, a bateria mostra somente um dos cinco glifos semânticos de nível e o Bluetooth mostra somente seu estado; percentual, carregamento e dispositivo conectado aparecem na expansão. A rede mantém ícone e nome no modo compacto: SSID real no Wi-Fi, `Ethernet` em hardware físico e `Rede` para Ethernet virtualizada. O Wi-Fi usa exclusivamente a família `nf-md-wifi_strength_*`, com estados outline, fraco, médio, forte e desconectado centralizados em `Design.qml`.

O seletor de papéis de parede recebe foco exclusivo assim que `Alt+K` o abre. A busca `Pesquisar papel de parede...` compara nomes sem diferenciar maiúsculas, acentos, hífens, sublinhados e espaços. As setas navegam espacialmente pela grade, `Enter` aplica somente uma seleção filtrada válida e `Escape` fecha. A altura acompanha a quantidade de linhas até o limite da tela; as miniaturas continuam assíncronas e armazenadas pelo cache de imagens do Qt.

O histórico de clipboard registra texto e imagem com dois watchers MIME do `wl-paste` e armazena os bytes originais no `cliphist`. Um único supervisor mantém ambos os watchers, segura um `flock` no runtime do usuário e impede duplicação após recargas do Hyprland. Cada gravação publica um marcador atômico em `$XDG_CACHE_HOME/hyprism/state/clipboard-event`; o `ClipboardService` observa esse arquivo e relê o banco sem reiniciar o Quickshell. O painel classifica o preview, gera miniaturas PNG proporcionais de até 420×240 em `$XDG_CACHE_HOME/hyprism/clipboard`, mantém no máximo 64 miniaturas e usa um ícone neutro quando a prévia falha. Restaurar uma imagem executa `cliphist decode` diretamente para `wl-copy --type image/...`; o caminho da miniatura nunca é copiado como texto.

Notificações flutuantes formam uma lista centralizada de até quatro cartões, ou três em telas baixas. Cada cartão expira individualmente, títulos e corpos têm limites de linhas, alterações com o mesmo ID substituem a geração anterior e excedentes permanecem no histórico com um contador compacto. O Hub suprime temporariamente a pilha flutuante para preservar seus controles, sem descartar o histórico.

O layout tiled usa `gaps_in = 3` e `gaps_out = 8`. A reserva superior da ilha continua independente desses espaços e o fullscreen continua removendo somente a superfície persistente e a reserva do monitor afetado. Janelas de cliente usam raio de 10 px; os raios próprios do Quickshell não são afetados.

A borda ativa usa exclusivamente o papel semântico `secondary_container` do Matugen e a inativa usa `inactive_border`, derivado de `outline_variant`; ambos têm fallbacks Lua válidos. As animações do compositor usam uma curva Bézier curta sem spring ou overshoot. Abertura, fechamento, movimento, fade, layers e workspaces recebem durações próprias entre 1,0 e 2,4 unidades do Hyprland, mantendo movimento visível sem a cauda lenta anterior.

A tela configurada em `config/user.json` tem prioridade quando existe. Em seguida são usadas a tela focada do Hyprland e a primeira tela enumerada pelo Quickshell. Nenhum nome como `eDP-1`, `HDMI-A-1` ou `Virtual-1` é codificado.

## Terminal

Foot é o terminal padrão porque é um terminal Wayland pequeno, rápido e adequado ao ambiente gráfico virtual. `Alt+Return` é um atalho direto do Hyprland para o programa centralizado em `modules/programs.lua`; ele não depende do Quickshell.

`config/foot/foot.ini` usa JetBrains Mono Nerd Font 11.5, padding de 10 px, cursor beam, fundo escuro com opacidade 0,94 e a mesma paleta semântica do shell. Kitty permanece instalado e configurado como alternativa, mas não é o padrão. `$TERMINAL` também aponta para `foot`.

## Papel de parede e cores

```text
papel de parede
  └─ extração da cor-fonte fiel
      └─ Matugen para superfícies semânticas
          ├─ Quickshell
          ├─ Hyprland Lua
          ├─ Hyprlock
          ├─ Foot e Kitty
          ├─ GTK 2/3/4 e libadwaita sobre Colloid-Hyprism
          ├─ pastas do Hyprism-Papirus
          └─ Kvantum para Qt 5/6
```

`scripts/theme/generate-theme.py` é o gerador central. Uma miniatura limitada do wallpaper fornece a cor representativa mais relevante; a transformação HLS mantém o matiz, limita apenas saturação extrema e posiciona a luminosidade numa faixa útil de 0,48 a 0,72 antes da correção mínima de contraste. O resultado fica mais claro que a cor-fonte escura sem se transformar num pastel Material. O `primary` tonal do Material não é usado como destaque do Hyprism. Matugen continua responsável por fundo, superfícies, texto, cores de apoio e erro. O gerador cria:

- `~/.cache/hyprism/theme/theme.json` para Quickshell;
- `~/.cache/hyprism/theme/hyprland.lua` para bordas do Hyprland;
- `~/.cache/hyprism/theme/hyprlock-colors.conf` e `hyprlock.conf` completo para a tela de bloqueio;
- `~/.cache/hyprism/theme/foot.ini` com foreground, background, cursor, seleção e as 16 cores ANSI;
- `~/.cache/hyprism/theme/kitty.conf` e aplicação remota nas janelas Kitty compatíveis;
- `~/.cache/hyprism/theme/colloid/_color-palette-matugen.scss` como entrada semântica do Colloid;
- `~/.cache/hyprism/theme/colloid-gtk-4.0/` como saída fixa do libadwaita;
- `~/.cache/hyprism/theme/icons/Hyprism-Papirus` como tema herdado de ícones, contendo somente pastas recoloridas;
- `~/.cache/hyprism/theme/kvantum/Hyprism/` com SVG, configuração e esquema de cores do Kvantum.

Todos os artefatos são gerados por completo em um arquivo temporário, validados contra conteúdo vazio ou não resolvido e publicados por substituição atômica. Uma falha em Matugen preserva toda a paleta anterior; uma falha de um consumidor preserva seu último arquivo válido e não corrompe os demais. `scripts/system/publish-json` oferece o mesmo fluxo para uma configuração JSON produzida por outra ferramenta. Os leitores do shell aplicam debounce, mantêm o último estado válido e usam os padrões embutidos quando o arquivo ainda não existe ou está vazio.

O instalador copia os wallpapers incluídos e executa a pipeline inicial antes de considerar Hyprlock pronto. Assim, `hyprlock-colors.conf`, o `hyprlock.conf` dinâmico completo e `state/lock-wallpaper` já existem no primeiro bloqueio. A configuração instalada em `~/.config/hypr/hyprlock.conf` é um fallback autossuficiente de cor sólida; `scripts/system/lock` executa o arquivo dinâmico quando todos os recursos são válidos e faz `exec hyprlock` com o fallback caso contrário. `Alt+L` continua sendo um binding direto do Hyprland, sem depender do Quickshell. Para evitar a captura inicial que falhava no caminho gráfico do VirtualBox, o lock desativa seu próprio fade e seleciona screencopy por memória compartilhada. `scripts/system/validate-hyprlock` passa os dois arquivos pelo parser real do Hyprlock usando deliberadamente um display Wayland inexistente, portanto valida propriedades e cores sem bloquear a sessão. A instalação oficial usa uma única transação `pacman -Syu` para não misturar versões de Hyprlock, Hyprland, aquamarine e Mesa.

GTK 2, GTK 3, GTK 4 e libadwaita usam `Colloid-Hyprism-Dark-Matugen`. O template versionado em `config/matugen/templates/colloid-gtk-theme.scss` conserva as 111 variáveis do template Matugen/Colloid comprovado no ambiente de desenvolvimento: papéis semânticos claros e escuros, aliases legados, escala cinza, seleção e cores de janela. O acento escuro é substituído pelo acento canônico exato do Hyprism; as demais cores continuam vindo da paleta semântica do Matugen. Não existe mais uma camada CSS GTK ad-hoc sobre um Colloid estático.

`Hyprism-Papirus` herda `Papirus-Dark`, `Papirus` e `hicolor`. O gerador seleciona os SVGs `folder-blue` do Papirus como templates, substitui o corpo `#5294e2` pelo hexadecimal canônico exato e deriva somente sombra e dobra desse mesmo valor. Downloads, Documentos, Imagens, Música, Vídeos, Desktop, Público e demais overlays continuam intactos; os ícones de aplicativos permanecem herdados e não são recoloridos. A geração ocorre numa nova árvore, a referência ativa é trocada atomicamente e somente duas gerações são retidas para cobrir leitores concorrentes sem crescimento ilimitado. Aplicativos já abertos podem exigir reabertura para limpar seu cache de ícones.

`scripts/system/install-colloid-theme` obtém [Colloid GTK Theme](https://github.com/vinceliuice/Colloid-gtk-theme) diretamente do upstream público na revisão `6c2dc65865628bda9fdc8157a30cd5eda6fd41f9`. O patch versionado em `config/matugen/colloid-matugen.patch` reproduz somente a integração Matugen do setup funcional: leitura de `_color-palette-matugen.scss`, variante `Matugen` e fallbacks de assets GTK 2, Labwc e Plank. A compilação usa `--color dark --libadwaita fixed --tweaks matugen rimless`. O SHA-256 da paleta instalada dispensa recompilações sem mudança. Uma nova árvore é compilada e validada num destino isolado; somente depois GTK 2/3/4 e a saída fixa do libadwaita substituem a geração ativa. Falha de download, SCSS ou `sassc` mantém integralmente o último tema funcional.

Qt 6 usa `QT_QPA_PLATFORMTHEME=qt6ct`, uma única chave válida de tema de plataforma. Qt 5 e Qt 6 usam `QT_STYLE_OVERRIDE=kvantum` como motor visual e compartilham o tema dinâmico `Hyprism` selecionado em `~/.config/Kvantum/kvantum.kvconfig`. As configurações de `qt5ct` e `qt6ct` mantêm Hyprism-Papirus e Kvantum selecionados para inspeção ou execução específica de cada geração, sem concatenar nomes de plugins incompatíveis. Novos processos Qt recebem a nova paleta imediatamente; processos já abertos podem precisar ser reiniciados.

## Atalhos principais

| Atalho | Ação |
| --- | --- |
| `Alt+Return` | Foot, diretamente pelo Hyprland |
| `Alt+E` | Gerenciador de arquivos |
| `Alt+B` | Navegador |
| `Alt+R` | Aplicativos |
| `Alt+K` | Papéis de parede |
| `Alt+Super+K` | Papel de parede aleatório |
| `Alt+Shift+V` | Área de transferência |
| `Alt+Tab` / `Alt+Shift+Tab` | Troca de janelas; soltar Alt confirma |
| `Alt+Shift+N` | Rede |
| `Alt+Shift+I` | Economia de energia |
| `Alt+Shift+L` | Menu de energia do Quickshell |
| `Alt+M` | Encerrar sessão diretamente pelo Hyprland |
| `Alt+Shift+E` | Recarregar ou iniciar o Quickshell |
| `Alt+Ctrl+S` | Modo noturno |
| `Alt+Ctrl+P` | Seletor de cor |
| `Alt+Shift+S` | Captura de região |
| `Alt+Shift+F` | Captura do monitor focado |
| `Alt+L` | Bloqueio com Hyprlock |
| `Alt+P` | Alternar pseudotile pela API Lua atual |
| `Alt+W` | Fechar janela diretamente pelo Hyprland |
| `Alt+1…0` | Workspaces 1–10 |

## VirtualBox

Uma VM normalmente oferece Ethernet e não oferece bateria, Wi-Fi, Bluetooth, brilho, GPU NVIDIA ou sensores físicos. Esses estados são válidos. Quando o adaptador Ethernet pertence a uma máquina virtual, a interface usa o rótulo neutro `Rede` e os detalhes informam `Adaptador virtual`; ela não tenta inferir o SSID do host. A ilha continua visível, o widget de data/hora e o widget de CPU/memória são criados, e controles de hardware ausente ficam ocultos ou indisponíveis. Em particular, o controle de brilho só existe quando `brightnessctl` encontra um controlador real.

Foot não usa o caminho de renderização do Kitty e é o primeiro terminal a testar com `Alt+Return`. Mantenha aceleração 3D e recursos de vídeo da VM compatíveis com a versão do Hyprland usada pelo Arch.

O Quickshell usa por padrão o backend `software` do Qt Quick. Esse backend rasteriza a interface sem depender de uma superfície EGL e evita as falhas `Could not create EGL surface`, `eglSwapBuffers failed` e `Wayland connection experienced a fatal error` observadas com o adaptador gráfico do VirtualBox. A configuração vale apenas para o processo do Quickshell; Hyprland, Foot e os demais aplicativos mantêm seus próprios backends gráficos.

Depois de uma instalação na VM, `pgrep -af 'wl-paste.*clipboard-store'` deve mostrar exatamente dois processos, um para texto e outro para imagem. `cliphist list` pode responder que ainda não existe banco antes da primeira cópia; isso é um estado vazio normal. Depois de copiar conteúdo, o marcador `$XDG_CACHE_HOME/hyprism/state/clipboard-event` muda e o painel deve atualizar imediatamente. Para o lockscreen, `~/.local/share/hyprism/scripts/system/validate-hyprlock ~/.config/hypr/hyprlock.conf` repete a validação segura; o teste visual final continua sendo `Alt+L` dentro da VM.

O clima inicial está configurado para São Paulo, com fuso `America/Sao_Paulo`. Local, latitude, longitude, fuso e intervalo podem ser alterados no bloco `weather` de `config/user.json` antes de executar novamente o instalador.

Os widgets persistentes formam duas colunas compactas tratadas como uma única composição e continuam abaixo de janelas normais. Na instalação nova, o grupo fica centralizado na área útil abaixo da reserva superior; data/clima, CPU/RAM, rede, armazenamento ficam na primeira coluna, enquanto uptime/carga, sensores, serviços, tarefas, processos e mídia ficam na segunda. Cards contextuais desaparecem quando não há sensores ou tarefas, e as colunas recalculam a própria altura sem deixar slots vazios. CPU, RAM e rede usam sparklines nativas com históricos limitados; o wallpaper permanece visível ao redor das superfícies translúcidas.

## Widgets de monitoramento

Todos os widgets ficam em `shell.widgets` de `config/user.json`. O formato antigo com booleanos continua aceito; um campo ausente recebe o padrão atual. Alterações publicadas atomicamente são aplicadas pelo hot reload. O mínimo para desativar um widget é:

```json
{
  "shell": {
    "widgets": {
      "network": { "enabled": false }
    }
  }
}
```

`shell.widgetLayout.position` aceita `center`, `top-left`, `top-right`, `bottom-left` e `bottom-right`. O padrão do arquivo instalado é `center` em cada monitor. Configurações antigas sem `position` continuam usando `shell.widgetLayout.side`: `left` corresponde a `top-left`, e os demais valores a `top-right`. O centro considera a reserva compacta e a geometria da própria tela, sem coordenadas globais entre monitores.

| Chave | Padrão | Dados e opções |
| --- | --- | --- |
| `clock` | habilitado | Relógio e data em pt-BR |
| `weather` | habilitado | Condição e temperatura da configuração de clima |
| `media` | habilitado | Faixa MPRIS atual; oculta sem mídia |
| `system` | habilitado | CPU e RAM com 60 amostras |
| `network` | habilitado | Download/upload a cada 1 s; `historySamples` entre 15 e 180, `interface` com nome ou `auto` |
| `storage` | habilitado | Uso dos mounts de `mounts`; `/home` é removido quando usa a mesma origem de `/` |
| `sensors` | habilitado | Descoberta por `hwmon` e `thermal`; oculta quando nenhum sensor confiável existe |
| `uptime` | habilitado | Uptime, cargas de 1/5/15 min, núcleos e total de processos |
| `services` | habilitado | `items` monitorados; `problemOnly` oculta o card saudável |
| `tasks` | habilitado | Até `limit` tarefas registradas por IPC; oculta quando vazia |
| `processes` | habilitado | Top CPU e memória por `/proc` a cada 3 s; `limit` entre 1 e 6 |

Rede lê contadores de `/proc/net/dev` da conexão ativa do NetworkManager ou da interface configurada. Loopback, bridges Docker, `veth` e `virbr` não são somados. Armazenamento usa `statvfs` a cada 60 s. Sensores e uptime são atualizados a cada 5 s. O monitor de serviços consulta somente estado, sem sudo ou ações, a cada 15 s. O coletor dedicado não é iniciado quando armazenamento, sensores, uptime, serviços e processos estão todos desabilitados.

Itens de serviço aceitam nome visível, unit e escopo:

```json
{
  "services": {
    "enabled": true,
    "problemOnly": false,
    "items": [
      { "name": "Rede", "unit": "NetworkManager.service", "scope": "system" },
      { "name": "PipeWire", "unit": "pipewire.service", "scope": "user" }
    ]
  }
}
```

O modelo de tarefas contém `id`, `title`, `subtitle`, `progress`, `indeterminate`, `status`, `startedAt`, `eta` em segundos e `source`. Scripts podem registrar progresso sem daemon adicional:

```bash
scripts/system/shell-ipc tasks add '{"id":"tema","title":"Aplicando tema","progress":20,"status":"running"}'
scripts/system/shell-ipc tasks update tema '{"progress":75,"eta":30}'
scripts/system/shell-ipc tasks finish tema
scripts/system/shell-ipc tasks fail tema
scripts/system/shell-ipc tasks remove tema
scripts/system/shell-ipc tasks list
```

`finish` mantém 100% brevemente antes de remover a tarefa; `fail` preserva o erro por cinco segundos. Sem tarefas ativas, nenhum card vazio ocupa o desktop.

A reserva superior compacta usa 8 px de margem, 44 px de ilha e 4 px de respiro. A superfície de reserva permanece fixa e totalmente transparente durante expansões. O overlay ignora exclusões de outras camadas, usa a mesma origem absoluta no topo central e mantém um canvas Wayland estável; a forma desenhada, seu recorte e sua máscara de entrada compartilham uma única geometria animada. Launcher, hub, clipboard, seletor de wallpaper, Alt+Tab e menu de energia crescem para baixo sem ampliar a reserva. Cada tela detectada recebe sua própria ilha visual e seus próprios widgets. Painéis transitórios usam primeiro a tela invocadora e, para atalhos, o monitor focado pelo Hyprland.

As transições de opacidade usam 80 ms, respostas rápidas usam 110 ms e morphs de geometria usam 150 ms. Um único progresso interpola largura, altura e raio, sem animações concorrentes do `PanelWindow`, do fundo e do recorte. A ilha compacta, painéis, cards, botões, notificações, widgets, launcher, OSD e Alt+Tab usam raio predominante de 9 px.

Os workspaces aparecem como até cinco células quadradas numeradas: o workspace ativo usa preenchimento de destaque, ocupados usam superfície elevada, vizinhos vazios ficam atenuados e urgentes usam a cor semântica de erro. A seleção considera o workspace ativo, seus vizinhos e workspaces ocupados ou urgentes sem alargar indefinidamente a ilha. A bateria usa a família Font Awesome do Nerd Font entre `nf-fa-battery_0` e `nf-fa-battery_4`, com limiares de carga centralizados e um raio discreto ao carregar.

Painéis interativos usam o foco exclusivo da superfície layer-shell e `HyprlandFocusGrab`, solicitam foco do primeiro controle depois que a superfície está estável e liberam o grab ao fechar. Clique na ilha e IPC passam pelas mesmas ações semânticas do controlador central. O launcher mostra no máximo seis linhas antes de rolar e calcula a altura a partir da quantidade filtrada. Os estados de Wi-Fi, Bluetooth, modo noturno e perfil de energia vêm do backend observado; o clique apenas inicia uma solicitação pendente e não altera a aparência ativa antecipadamente.

O seletor de wallpaper abre com foco no wallpaper atual ou no primeiro resultado. Setas navegam usando a quantidade responsiva de colunas, Enter aplica, Escape fecha, Tab leva deterministicamente à busca e seta para baixo retorna ao grid. A busca por nome ignora caixa, acentos, hífens e underscores; sem resultado, mantém o campo editável e mostra `Nenhum papel de parede encontrado`.

Notificações recebidas criam uma fotografia independente no histórico e mantêm o objeto do protocolo apenas no stack temporário. Expiração ou fechamento remove o toast e sinaliza o emissor sem apagar a fotografia. IDs de replacement atualizam a mesma entrada. `Limpar tudo` remove o histórico e os toasts correspondentes, mas o servidor continua aceitando novas notificações.

A mídia usa o serviço MPRIS nativo do Quickshell. A ilha compacta mostra artista e faixa truncados; a expansão mostra capa, título, artista, progresso, tempos e controles. O widget de mídia usa recorte proporcional da capa, os mesmos tokens de cor e controles de teclado. Sem player ou faixa válida, os dois elementos permanecem ocultos.

Em uma máquina física com aceleração Qt funcional, o backend RHI pode ser testado sem editar o repositório:

```bash
QT_QUICK_BACKEND=rhi qs --no-duplicate
```

## Solução de problemas

### Quickshell não iniciou

Execute estes comandos dentro da VM, depois de entrar no Hyprland:

```bash
pacman -Q quickshell
command -v qs
pgrep -af '(^|/)(qs|quickshell)( |$)'
readlink -f ~/.config/quickshell/default
readlink -f ~/.config/quickshell/hyprism
test -r ~/.config/quickshell/default/shell.qml && echo 'shell.qml encontrado'
test -x ~/.local/share/hyprism/scripts/system/start-shell && echo 'helper encontrado'
```

Confira a instância e os logs selecionando exatamente a configuração Hyprism:

```bash
qs list -a
qs -c default log -t 200
qs -c default ipc call shell status
sed -n '1,200p' ~/.cache/hyprism/quickshell-startup.log
```

Para testar o clone sem instalar e sem alterar o locale do host, execute na raiz do repositório:

```bash
HYPRISM_ROOT="$PWD" scripts/system/start-shell --development
HYPRISM_ROOT="$PWD" HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc shell status
```

O modo de desenvolvimento usa o mesmo launcher e o caminho explícito do repositório. Se outro daemon do desktop já possuir `org.freedesktop.Notifications`, o Quickshell registrará um único conflito de DBus; isso não impede painéis, estado ou foco. Na sessão instalada do Hyprism, o Quickshell continua sendo o servidor de notificações e o projeto não inicia Dunst ou SwayNC.

Somente quando `start-shell --development` define o escopo local, os modelos visuais descartáveis podem ser acionados sem assumir o serviço de notificações nem depender do banco real do clipboard:

```bash
HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc development mockNotifications 5
HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc development mockReplacement
HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc development dismissNewestToast
HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc development clearNotificationHistory
HYPRISM_QS_PATH="$PWD/config/quickshell/shell.qml" scripts/system/shell-ipc development mockClipboard
```

Esses endpoints ignoram chamadas na sessão instalada.

Para observar um erro de carregamento sem daemonizar, primeiro confirme que não há uma instância ativa e então execute na VM:

```bash
HYPRISM_ROOT="$HOME/.local/share/hyprism" qs --no-duplicate
```

Como `default` é a configuração canônica, esse comando é equivalente a usar `qs -c default --no-duplicate`.

Verifique também a configuração e o autostart do Hyprland:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
hyprctl configerrors
rg -n 'start-shell|hyprland.start' ~/.config/hypr
journalctl --user -b --no-pager | rg -i 'quickshell|hyprism|qml'
```

`Alt+Shift+E` tenta uma recarga IPC e, se não houver processo, inicia novamente a configuração correta. `Alt+Return`, fechamento de janelas, workspaces e `Alt+M` continuam funcionando sem Quickshell.

Confira as fontes e o tema de ícones instalados:

```bash
pacman -Q papirus-icon-theme ttf-nerd-fonts-symbols-mono fontconfig
fc-match 'Google Sans Flex'
fc-match 'Symbols Nerd Font Mono'
test -d /usr/share/icons/Papirus-Dark && echo 'Papirus-Dark encontrado'
test -s ~/.local/share/icons/Hyprism-Papirus/index.theme && echo 'Hyprism-Papirus encontrado'
```

Se os textos usarem uma fonte de fallback, execute `fc-cache -f` dentro da VM e encerre a sessão antes de testar novamente. O helper `install-google-sans-flex` verifica os três downloads antes de instalá-los em `~/.local/share/fonts/google-sans-flex`.

Se o log mencionar EGL, confirme que a configuração instalada contém o fallback do VirtualBox:

```bash
head -n 3 ~/.config/quickshell/default/shell.qml
QT_QUICK_BACKEND=software QSG_INFO=1 qs --no-duplicate
```

O segundo comando é apenas para diagnóstico dentro da VM e deve informar o backend de software antes de carregar a interface.

### Foot não abriu

```bash
pacman -Q foot
command -v foot
foot -C
readlink -f ~/.config/foot/foot.ini
test -s ~/.cache/hyprism/theme/foot.ini && echo 'tema do Foot encontrado'
```

`foot -C` apenas valida a configuração na VM. Se o arquivo gerado estiver ausente, execute novamente o instalador ou selecione um papel de parede com `hyprism-wallpaper set CAMINHO`.

### Verificação manual da estabilização

Na VM, confirme estes pontos depois de iniciar uma sessão nova:

- a área entre a ilha compacta e as janelas mede apenas a reserva compacta e não muda ao abrir painéis;
- o topo e o centro horizontal permanecem imóveis durante hover, abertura e fechamento de todos os painéis;
- um clique normal em qualquer área livre da ilha abre o hub, e o conteúdo expandido permanece clicável durante a animação;
- duas telas mantêm ilhas e widgets independentes durante movimento do ponteiro, hotplug e mudança de resolução;
- `Alt+R`, `Alt+K`, `Alt+Shift+V`, `Alt+Shift+N`, `Alt+Shift+L` e `Alt+Tab` recebem teclado imediatamente no monitor focado;
- o launcher cresce até seis resultados visíveis, reduz ao filtrar e rola resultados adicionais sem rastro colorido;
- notificações aparecem centralizadas abaixo da ilha, empilham para baixo e mostram um único estado vazio no histórico;
- toggles acompanham o estado real depois de sucesso ou falha, e recursos indisponíveis nunca aparecem ativos;
- o brilho aparece com slider em hardware compatível e fica oculto no VirtualBox sem backlight;
- ícones, títulos, valores e gráficos dos cards de CPU e memória mantêm a mesma linha e o mesmo recorte.

## Estrutura do repositório

```text
config/hypr/        configuração Lua modular do Hyprland
config/quickshell/  shell, painéis, widgets, serviços, notificações e OSD
config/foot/        configuração e tema de fallback do Foot
config/kitty/       suporte opcional ao Kitty
scripts/            backends, wallpaper e geração de tema
packages/           listas reproduzíveis de pacotes oficiais e AUR
wallpapers/         papéis de parede de teste incluídos
install.sh          implantação Arch reproduzível
```
