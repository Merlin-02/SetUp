#!/usr/bin/env bash

set -e

echo "🚀 Instalador inteligente Hyprland + imperative-dots"

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

# DETECTAR GPU

# =========================

echo "🧠 Detectando GPU..."

GPU=$(lspci | grep -E "VGA|3D")

echo "GPU detectada:"
echo "$GPU"

GPU_PACKAGES="mesa"

if echo "$GPU" | grep -qi "Intel"; then
echo "🟦 Intel detectado"
GPU_PACKAGES+=" vulkan-intel"
elif echo "$GPU" | grep -qi "AMD"; then
echo "🟥 AMD detectado"
GPU_PACKAGES+=" vulkan-radeon"
elif echo "$GPU" | grep -qi "NVIDIA"; then
echo "🟩 NVIDIA detectado"
GPU_PACKAGES="nvidia nvidia-utils nvidia-settings"
elif echo "$GPU" | grep -qi "VirtualBox"; then
echo "🟨 VirtualBox detectado"
GPU_PACKAGES="virtualbox-guest-utils mesa"
fi

# =========================

# DEPENDENCIAS COMPLETAS

# =========================

echo "📦 Instalando paquetes..."

sudo pacman -S --needed --noconfirm 
git base-devel 
hyprland waybar rofi dunst kitty swww 
swaync cava neovim 
networkmanager bluez bluez-utils 
pipewire pipewire-pulse wireplumber 
brightnessctl playerctl pamixer 
grim slurp wl-clipboard 
jq python noto-fonts noto-fonts-emoji 
ttf-jetbrains-mono 
sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg 
$GPU_PACKAGES

# =========================

# SERVICIOS BASE

# =========================

sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm

# VirtualBox service

if echo "$GPU" | grep -qi "VirtualBox"; then
sudo systemctl enable vboxservice
fi

# =========================

# CLONAR REPO

# =========================

if [ -d "$INSTALL_DIR" ]; then
echo "📁 Actualizando repo..."
cd "$INSTALL_DIR"
git pull
else
echo "📥 Clonando repo..."
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
fi

# =========================

# BACKUP

# =========================

mkdir -p "$HOME/.backup_dots"
cp -r "$HOME/.config" "$HOME/.backup_dots/" 2>/dev/null || true
cp -r "$HOME/.local" "$HOME/.backup_dots/" 2>/dev/null || true

# =========================

# COPIAR DOTFILES

# =========================

echo "⚙️ Aplicando configuración..."

cp -r .config/* "$HOME/.config/"
cp -r .local/* "$HOME/.local/" 2>/dev/null || true

# =========================

# PERMISOS

# =========================

chmod +x $HOME/.config/hypr/scripts/*.sh || true
chmod +x $HOME/.config/hypr/scripts/**/*.sh 2>/dev/null || true

# =========================

# BINARIOS EXTRA

# =========================

if [ -d "utils/bin" ]; then
chmod +x utils/bin/*
sudo cp utils/bin/* /usr/local/bin/
fi

# =========================

# FUENTES

# =========================

mkdir -p "$HOME/.local/share/fonts"
cp -r .local/share/fonts/* "$HOME/.local/share/fonts/" 2>/dev/null || true
fc-cache -fv

# =========================

# ZSH

# =========================

if [ -f ".config/zsh/.zshrc" ]; then
cp .config/zsh/.zshrc "$HOME/"
fi

# =========================

# SDDM

# =========================

if [ -d ".config/sddm/themes/matugen-minimal" ]; then
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r .config/sddm/themes/matugen-minimal /usr/share/sddm/themes/

```
sudo bash -c 'cat > /etc/sddm.conf <<EOF
```

[Theme]
Current=matugen-minimal
EOF'
fi

# =========================

# KEYBINDS FUNCIONALES

# =========================

echo "🎹 Configurando teclas F1-F12..."

cat >> "$HOME/.config/hypr/hyprland.conf" <<EOF

# === FUNCION KEYS ===

bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

EOF

# =========================

# FINAL

# =========================

echo ""
echo "✅ Instalación completa + hardware configurado"
echo "👉 Reinicia:"
echo "   reboot"
echo ""

