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
- cria `~/Imagens/Wallpapers` e `~/Imagens/Screenshots` sem apagar conteúdo existente;
- copia os arquivos runtime para `~/.local/share/hyprism`, sem depender do local original do clone;
- cria links para `~/.config/hypr`, `~/.config/quickshell/hyprism`, Foot, Kitty, GTK, Qt e a configuração do usuário;
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
      │           └─ qs -p ~/.config/quickshell/hyprism
      │               └─ shell.qml
      └─ config/quickshell
          ├─ ilha e painéis
          ├─ widgets de data e sistema
          ├─ notificações e OSD
          └─ serviços opcionais resilientes
```

`config/hypr/hyprland.lua` é o ponto de entrada Lua do Hyprland 0.55 ou posterior. Os módulos separam programas, monitores, aparência, entrada, layouts, regras, workspaces, atalhos, ambiente e autostart. Não há configuração Hyprland `.conf` ativa no repositório.

O Quickshell é iniciado uma única vez pelo evento `hyprland.start`. O helper usa o executável canônico `qs`, o caminho nomeado e explícito da configuração, `--no-duplicate` e a raiz runtime estável. O Hyprland já cria o processo de forma assíncrona, por isso o shell não usa uma segunda camada de daemonização. Recarregar a configuração do Hyprland não acumula processos do shell.

No primeiro boot, a paleta escura embutida mantém a ilha e os widgets utilizáveis mesmo sem arquivos gerados. Ausência de bateria, Wi-Fi, Bluetooth, brilho, GPU, sensores, MPRIS, clima ou histórico de clipboard produz um estado indisponível ou oculto, sem bloquear o `shell.qml`.

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

Uma VM normalmente oferece Ethernet e não oferece bateria, Wi-Fi, Bluetooth, brilho, GPU NVIDIA ou sensores físicos. Esses estados são válidos. A ilha continua visível, o widget de data/hora e o widget de CPU/memória são criados, e controles de hardware ausente ficam ocultos ou indisponíveis.

Foot não usa o caminho de renderização do Kitty e é o primeiro terminal a testar com `Alt+Return`. Mantenha aceleração 3D e recursos de vídeo da VM compatíveis com a versão do Hyprland usada pelo Arch.

## Solução de problemas

### Quickshell não iniciou

Execute estes comandos dentro da VM, depois de entrar no Hyprland:

```bash
pacman -Q quickshell
command -v qs
pgrep -af '(^|/)(qs|quickshell)( |$)'
readlink -f ~/.config/quickshell/hyprism
test -r ~/.config/quickshell/hyprism/shell.qml && echo 'shell.qml encontrado'
test -x ~/.local/share/hyprism/scripts/system/start-shell && echo 'helper encontrado'
```

Confira a instância e os logs selecionando exatamente a configuração Hyprism:

```bash
qs list -a
qs -p ~/.config/quickshell/hyprism log -t 200
qs -p ~/.config/quickshell/hyprism ipc call shell status
```

Para observar um erro de carregamento sem daemonizar, primeiro confirme que não há uma instância ativa e então execute na VM:

```bash
HYPRISM_ROOT="$HOME/.local/share/hyprism" qs -p "$HOME/.config/quickshell/hyprism" --no-duplicate
```

Verifique também a configuração e o autostart do Hyprland:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
hyprctl configerrors
rg -n 'start-shell|hyprland.start' ~/.config/hypr
journalctl --user -b --no-pager | rg -i 'quickshell|hyprism|qml'
```

`Alt+Shift+E` tenta uma recarga IPC e, se não houver processo, inicia novamente a configuração correta. `Alt+Return`, fechamento de janelas, workspaces e `Alt+M` continuam funcionando sem Quickshell.

### Foot não abriu

```bash
pacman -Q foot
command -v foot
foot -C
readlink -f ~/.config/foot/foot.ini
test -s ~/.cache/hyprism/theme/foot.ini && echo 'tema do Foot encontrado'
```

`foot -C` apenas valida a configuração na VM. Se o arquivo gerado estiver ausente, execute novamente o instalador ou selecione um papel de parede com `hyprism-wallpaper set CAMINHO`.

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
