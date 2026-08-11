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
- cria `~/Imagens/Wallpapers` e `~/Imagens/Screenshots` sem apagar conteúdo existente;
- copia os arquivos runtime para `~/.local/share/hyprism`, sem depender do local original do clone;
- cria links para `~/.config/hypr`, `~/.config/quickshell/default`, o alias `~/.config/quickshell/hyprism`, Foot, Kitty, GTK, Qt e a configuração do usuário;
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

O Quickshell é iniciado uma única vez pelo evento `hyprland.start`. O helper usa o executável canônico `qs`, a configuração nomeada `default`, `--no-duplicate` e a raiz runtime estável. `QS_CONFIG_NAME=default` centraliza a seleção usada pelo Hyprland e pelos scripts. O alias `hyprism` preserva compatibilidade, enquanto `qs` sem argumentos e `qs -c default` encontram o mesmo `shell.qml`. O Hyprland já cria o processo de forma assíncrona, por isso o shell não usa uma segunda camada de daemonização. Recarregar a configuração do Hyprland não acumula processos do shell.

No primeiro boot, a paleta escura embutida mantém a ilha e os widgets utilizáveis mesmo sem arquivos gerados. Ausência de bateria, Wi-Fi, Bluetooth, brilho, GPU, sensores, MPRIS, clima ou histórico de clipboard produz um estado indisponível ou oculto, sem bloquear o `shell.qml`.

Google Sans Flex é a família primária de texto da interface. Symbols Nerd Font Mono é usada somente para a iconografia semântica do shell. Os tamanhos, pesos, alturas, espaçamentos, raios e glifos ficam centralizados em `Design.qml`, e componentes compartilhados mantêm a linha de base e o ritmo vertical da ilha.

Ícones de aplicativos são resolvidos a partir do campo `Icon` dos arquivos `.desktop` pelo tema Papirus-Dark, com fallback para `application-x-executable`. Isso vale para o launcher, o Alt+Tab, notificações e o aplicativo de mídia. Estados do sistema usam exclusivamente o mapa semântico Nerd Font; emoji não é usado como ícone de status.

O `PanelWindow` da ilha mantém uma zona exclusiva constante composta pela margem superior, pela altura compacta e pelo respiro configurado. Janelas tiled e maximizadas começam abaixo dessa faixa. Launcher, controles, notificações, mídia expandida e Alt+Tab aumentam a própria superfície acima das aplicações sem alterar a zona exclusiva, portanto a expansão funciona como overlay e não reorganiza as janelas.

O Alt+Tab usa os toplevels expostos pelo Quickshell e mantém uma lista MRU atualizada por eventos de foco. A primeira troca seleciona a janela focada anteriormente; repetições avançam ou recuam e soltar Alt ativa a seleção, inclusive em outro workspace. A interface mostra ícone Papirus, nome do aplicativo e título, com fallback intencional quando algum metadado está ausente.

Launcher, papéis de parede, clipboard, redes, Bluetooth, central de controle, notificações, energia, mídia e Alt+Tab aceitam navegação por teclado. `Escape` fecha, `Enter` ativa, setas percorrem listas, grades e controles, e `Tab` mantém a travessia de foco onde não conflita com o alternador de janelas.

A tela configurada em `config/user.json` tem prioridade quando existe. Em seguida são usadas a tela focada do Hyprland e a primeira tela enumerada pelo Quickshell. Nenhum nome como `eDP-1`, `HDMI-A-1` ou `Virtual-1` é codificado.

## Terminal

Foot é o terminal padrão porque é um terminal Wayland pequeno, rápido e adequado ao ambiente gráfico virtual. `Alt+Return` é um atalho direto do Hyprland para o programa centralizado em `modules/programs.lua`; ele não depende do Quickshell.

`config/foot/foot.ini` usa JetBrains Mono Nerd Font 11.5, padding de 10 px, cursor beam, fundo escuro com opacidade 0,94 e a mesma paleta semântica do shell. Kitty permanece instalado e configurado como alternativa, mas não é o padrão. `$TERMINAL` também aponta para `foot`.

## Papel de parede e cores

```text
papel de parede
  └─ Matugen
      └─ paleta semântica com contraste corrigido
          ├─ Quickshell
          ├─ Hyprland Lua
          ├─ Foot
          └─ Kitty
```

`scripts/theme/generate-theme.py` é o gerador central. Ele cria:

- `~/.cache/hyprism/theme/theme.json` para Quickshell;
- `~/.cache/hyprism/theme/hyprland.lua` para bordas do Hyprland;
- `~/.cache/hyprism/theme/foot.ini` com foreground, background, cursor, seleção e as 16 cores ANSI;
- `~/.cache/hyprism/theme/kitty.conf` e aplicação remota nas janelas Kitty compatíveis.

O instalador prepara `foot.ini` com uma paleta de fallback antes de qualquer terminal ser aberto. Novas janelas Foot leem a paleta atual. GTK permanece em Adwaita escuro e Qt usa `qt6ct` com Fusion.

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

O clima inicial está configurado para São Paulo, com fuso `America/Sao_Paulo`. Local, latitude, longitude, fuso e intervalo podem ser alterados no bloco `weather` de `config/user.json` antes de executar novamente o instalador.

Os widgets de data e clima formam uma composição compacta no canto da tela. O monitor de sistema mantém 60 amostras limitadas de CPU e RAM e desenha sparklines nativas no QML. GPU, temperatura, bateria e tráfego aparecem somente quando disponíveis. O backend coleta CPU, RAM e throughput a cada segundo, estados gerais a cada três segundos e Bluetooth/temperatura a cada cinco segundos, sem executar comandos por quadro de animação.

A reserva superior compacta usa 8 px de margem, 44 px de ilha e 4 px de respiro. A superfície de reserva permanece fixa durante expansões; launcher, hub, clipboard, seletor de wallpaper, Alt+Tab e menu de energia são desenhados por uma superfície de overlay com máscara limitada à forma visível. Cada tela detectada recebe sua própria ilha e seus próprios widgets. Painéis transitórios usam primeiro a tela invocadora e, para atalhos, o monitor focado pelo Hyprland.

Painéis interativos solicitam foco de teclado ao abrir e o liberam ao fechar. O launcher mostra no máximo seis linhas antes de rolar e calcula a altura a partir da quantidade filtrada. Os estados de Wi-Fi, Bluetooth, modo noturno e perfil de energia vêm do backend observado; o clique apenas inicia uma solicitação pendente e não altera a aparência ativa antecipadamente.

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
