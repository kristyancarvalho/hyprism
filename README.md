<div align="center">

# Hyprism

**Dotfiles automatizados para um ambiente Hyprland pessoal, coeso e dinâmico.**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58E1FF?style=flat-square)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-QML-41CD52?style=flat-square&logo=qt&logoColor=white)](https://quickshell.org/)
[![Matugen](https://img.shields.io/badge/Matugen-dynamic_color-8B5CF6?style=flat-square)](https://github.com/InioX/matugen)

</div>

> Hyprism é um conjunto de dotfiles automatizados para uma experiência personalizada no Hyprland. Quickshell fornece a ilha, os painéis e os widgets; Matugen propaga as cores do wallpaper por toda a sessão.

## Demonstração

[![Tour automatizado do Hyprism](assets/demo/hyprism-tour.webp)](assets/demo/hyprism-tour.mp4)

| Desktop e ilha compacta | Ilha expandida |
| --- | --- |
| ![Desktop com ilha compacta e paleta verde](assets/screenshots/desktop.png) | ![Ilha expandida e paleta verde](assets/screenshots/island-expanded.png) |
| **Widgets do desktop** | **Launcher** |
| ![Widgets do desktop com paleta roxa](assets/screenshots/desktop-widgets.png) | ![Launcher com paleta azul](assets/screenshots/launcher.png) |
| **Central de controle** | **Histórico de notificações** |
| ![Central de controle com paleta laranja](assets/screenshots/control-center.png) | ![Histórico de notificações com paleta laranja](assets/screenshots/notifications.png) |
| **Rede** | **Bluetooth** |
| ![Painel de rede com paleta azul](assets/screenshots/network.png) | ![Painel Bluetooth com paleta roxa](assets/screenshots/bluetooth.png) |
| **Área de transferência** | **Seletor de emoji** |
| ![Área de transferência com paleta roxa](assets/screenshots/clipboard.png) | ![Seletor de emoji com paleta roxa](assets/screenshots/emoji-picker.png) |
| **Energia** | **Gravação** |
| ![Menu de energia com paleta laranja](assets/screenshots/power-menu.png) | ![Seletor de gravação com paleta laranja](assets/screenshots/recording.png) |
| **Papéis de parede** | **Troca de janelas** |
| ![Seletor de papéis de parede com paleta roxa](assets/screenshots/wallpaper-picker.png) | ![Troca de janelas com clientes reais em outros workspaces](assets/screenshots/window-switcher.png) |

## O que configura

- Hyprland em Lua: monitores, workspaces, gestos, regras, ambiente, atalhos e autostart.
- Quickshell: ilha morfológica, launcher, troca de janelas, controles, notificações, OSD e widgets de monitoramento.
- Temas Matugen para Hyprland, Hyprlock, SDDM, GTK, Kvantum, Kitty, Foot, Starship, tmux, Neovim, Fastfetch e Zathura.
- Índice de aplicativos nativos e Flatpak com atualização ao vivo, além de portais Wayland integrados.
- Capturas, gravação de região ou monitor, clipboard, modo noturno e controles de áudio, brilho, rede e Bluetooth.

## Requisitos

- Arch Linux com acesso à internet durante o provisionamento.
- Um usuário normal com `sudo`; o instalador precisa de root para pacotes, fontes e SDDM.
- Hardware e drivers compatíveis com uma sessão Hyprland/Wayland atual.

## Instalação

```bash
git clone https://github.com/kristyancarvalho/hyprism.git
cd hyprism
sudo ./install.sh --user "$USER"
```

> [!WARNING]
> A instalação atualiza pacotes e substitui configurações gerenciadas do usuário. Conflitos são movidos para `~/.local/state/hyprism/backups/` antes da criação dos links.

Para reaplicar apenas os arquivos depois que todas as dependências já estiverem instaladas:

```bash
sudo ./install.sh --user "$USER" --no-packages
```

Os wallpapers ficam em `~/Imagens/Wallpapers`. Para aplicar um arquivo pela mesma pipeline usada pelo seletor:

```bash
hyprism-wallpaper set ~/Imagens/Wallpapers/arquivo.png
```

## Atalhos essenciais

| Atalho | Ação |
| --- | --- |
| `Super+Return` | Abrir Kitty |
| `Super+R` | Abrir o launcher |
| `Super+Tab` / `Super+Shift+Tab` | Navegar pelas janelas; soltar `Super` confirma |
| `Super+K` / `Super+Alt+K` | Escolher / sortear wallpaper |
| `Super+Shift+V` | Abrir a área de transferência |
| `Super+Shift+N` | Abrir o painel de rede |
| `Ctrl+.` | Abrir o seletor de emoji |
| `Super+Shift+R` | Selecionar ou encerrar uma gravação |
| `Super+Shift+S` / `Super+Shift+F` | Capturar região / monitor focado |
| `Super+L` | Bloquear com Hyprlock |
| `Super+Ctrl+S` | Alternar o modo noturno |
| `Super+B` | Abrir o Zen Browser |
| `Super+1…0` | Ir aos workspaces 1–10 |

## Créditos e licenças

Hyprism integra projetos como [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.org/), [Matugen](https://github.com/InioX/matugen), [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme) e [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme). Os componentes vendorizados mantêm suas atribuições e licenças nos respectivos diretórios, incluindo [KSDDM](themes/ksddm-hyprism/LICENSE) e [NvChad](config/nvim/LICENSE).
