#!/usr/bin/env bash

set -e

echo "🚀 Hyprland Smart Installer (imperative-dots)"

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

# Fallback SIEMPRE válido

GPU_PACKAGES=(mesa)

if echo "$GPU" | grep -qi "NVIDIA"; then
echo "🟩 NVIDIA detectado"
GPU_PACKAGES=(nvidia nvidia-utils nvidia-settings)
elif echo "$GPU" | grep -qi "Intel"; then
echo "🟦 Intel detectado"
GPU_PACKAGES=(mesa vulkan-intel)
elif echo "$GPU" | grep -qi "AMD"; then
echo "🟥 AMD detectado"
GPU_PACKAGES=(mesa vulkan-radeon)
fi

# VM override

if [ "$VIRT" != "none" ]; then
echo "🟨 Entorno virtual detectado ($VIRT)"
GPU_PACKAGES=(mesa)
fi

echo "Paquetes GPU: ${GPU_PACKAGES[*]}"

# =========================

# LISTA DE PAQUETES (ARRAY)

# =========================

PACKAGES=(
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
)

# =========================

# INSTALACIÓN SEGURA

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

echo "📥 Clonando repo..."

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

mkdir -p "$HOME/.backup_dots"
cp -r "$HOME/.config" "$HOME/.backup_dots/" 2>/dev/null || true
cp -r "$HOME/.local" "$HOME/.backup_dots/" 2>/dev/null || true

# =========================

# COPIAR CONFIG

# =========================

echo "⚙️ Aplicando dotfiles..."

cp -r .config/* "$HOME/.config/"
cp -r .local/* "$HOME/.local/" 2>/dev/null || true

# =========================

# PERMISOS

# =========================

chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# =========================

# BINARIOS

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

# SDDM

# =========================

if [ -d ".config/sddm/themes/matugen-minimal" ]; then
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r .config/sddm/themes/matugen-minimal /usr/share/sddm/themes/

```
echo -e "[Theme]\nCurrent=matugen-minimal" | sudo tee /etc/sddm.conf
```

fi

# =========================

# FINAL

# =========================

echo ""
echo "✅ Instalación completada sin errores"
echo "👉 Reinicia:"
echo "   reboot"
echo ""

