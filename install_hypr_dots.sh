#!/usr/bin/env bash

set -e

echo "🚀 Hyprland FULL Smart Installer (imperative-dots)"

REPO_URL="https://github.com/ilyamiro/imperative-dots.git"
INSTALL_DIR="$HOME/imperative-dots"

# =========================

# NO ROOT

# =========================

if [ "$EUID" -eq 0 ]; then
echo "❌ No ejecutar como root"
exit 1
fi

# =========================

# DETECTAR ENTORNO

# =========================

echo "🧠 Detectando entorno..."

VIRT=$(systemd-detect-virt)
LAPTOP=false

if ls /sys/class/power_supply 2>/dev/null | grep -q BAT; then
LAPTOP=true
fi

echo "Virtualización: $VIRT"
echo "Laptop: $LAPTOP"

# =========================

# DETECTAR GPU

# =========================

echo "🎮 Detectando GPU..."

GPU=$(lspci | grep -E "VGA|3D" || true)
echo "$GPU"

# Fallback seguro

GPU_PACKAGES=(mesa)

if echo "$GPU" | grep -qi "NVIDIA"; then
GPU_PACKAGES=(nvidia nvidia-utils nvidia-settings)
elif echo "$GPU" | grep -qi "Intel"; then
GPU_PACKAGES=(mesa vulkan-intel)
elif echo "$GPU" | grep -qi "AMD"; then
GPU_PACKAGES=(mesa vulkan-radeon)
fi

# VM override

if [ "$VIRT" != "none" ]; then
echo "🟨 VM detectada ($VIRT)"
GPU_PACKAGES=(mesa)
fi

echo "GPU packages: ${GPU_PACKAGES[*]}"

# =========================

# PAQUETES BASE

# =========================

PACKAGES=(
git base-devel zsh
hyprland waybar rofi dunst kitty swww
swaync cava neovim
networkmanager bluez bluez-utils
pipewire pipewire-pulse wireplumber
brightnessctl playerctl pamixer
grim slurp wl-clipboard
jq python noto-fonts noto-fonts-emoji
ttf-jetbrains-mono
sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
)

# =========================

# INSTALAR TODO

# =========================

echo "📦 Instalando paquetes..."

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" "${GPU_PACKAGES[@]}"

# =========================

# SERVICIOS

# =========================

echo "🔌 Activando servicios..."

sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm

if [ "$VIRT" != "none" ]; then
sudo systemctl enable vboxservice 2>/dev/null || true
fi

# =========================

# CLONAR REPO

# =========================

echo "📥 Clonando/actualizando repo..."

if [ -d "$INSTALL_DIR" ]; then
cd "$INSTALL_DIR"
git pull
else
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
fi

# =========================

# BACKUP

# =========================

echo "💾 Backup configs..."

mkdir -p "$HOME/.backup_dots"
cp -r "$HOME/.config" "$HOME/.backup_dots/" 2>/dev/null || true
cp -r "$HOME/.local" "$HOME/.backup_dots/" 2>/dev/null || true

# =========================

# COPIAR DOTFILES

# =========================

echo "⚙️ Aplicando dotfiles..."

cp -r .config/* "$HOME/.config/"
cp -r .local/* "$HOME/.local/" 2>/dev/null || true

# =========================

# PERMISOS SCRIPTS

# =========================

echo "🔧 Ajustando permisos..."

chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
find "$HOME/.config/hypr/scripts/" -type f -name "*.sh" -exec chmod +x {} ; 2>/dev/null || true

# =========================

# BINARIOS

# =========================

if [ -d "utils/bin" ]; then
echo "⚙️ Instalando binarios..."
chmod +x utils/bin/*
sudo cp utils/bin/* /usr/local/bin/
fi

# =========================

# FUENTES

# =========================

echo "🔤 Instalando fuentes..."

mkdir -p "$HOME/.local/share/fonts"
cp -r .local/share/fonts/* "$HOME/.local/share/fonts/" 2>/dev/null || true
fc-cache -fv

# =========================

# ZSH

# =========================

echo "🐚 Configurando ZSH..."

if [ -f ".config/zsh/.zshrc" ]; then
cp .config/zsh/.zshrc "$HOME/.zshrc"
fi

if [ "$SHELL" != "/bin/zsh" ]; then
chsh -s /bin/zsh
fi

# =========================

# SDDM

# =========================

if [ -d ".config/sddm/themes/matugen-minimal" ]; then
echo "🎨 Configurando SDDM..."

```
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r .config/sddm/themes/matugen-minimal /usr/share/sddm/themes/

echo -e "[Theme]\nCurrent=matugen-minimal" | sudo tee /etc/sddm.conf
```

fi

# =========================

# KEYBINDS

# =========================

echo "🎹 Configurando teclas multimedia..."

cat >> "$HOME/.config/hypr/hyprland.conf" <<EOF

# === MEDIA KEYS ===

bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
EOF

# Laptop brillo

if [ "$LAPTOP" = true ]; then
cat >> "$HOME/.config/hypr/hyprland.conf" <<EOF

# === BRIGHTNESS ===

bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
EOF
fi

# =========================

# FINAL

# =========================

echo ""
echo "✅ Instalación COMPLETA finalizada"
echo "🧠 Entorno:"
echo "   Virtualización: $VIRT"
echo "   Laptop: $LAPTOP"
echo ""
echo "👉 Reinicia el sistema:"
echo "   reboot"
echo ""

