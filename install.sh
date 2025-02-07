#!/bin/bash

#
# Copyright (C) 2024-2025 Vladimir `rifux` Blinkov
#
# SPDX-License-Identifier: MIT
#

set -e
t="$HOME/.cache/tumbleweed-hyprland-installer"
c="$HOME/.config/"

_log() {
    echo -e "\n$1"
}

_cleanup() {
    if [ -d "$t" ]; then
        sudo rm -rf "$t"
    fi

    for path in ags anyrun fish/auto-Hypr.fish fish/config.fish fish/fish_variables fontconfig foot fuzzel hypr mpv qt5ct wlogout zshrc.d chrome-flags.conf code-flags.conf starship.toml thorium-flags.conf; do
        if [ -e "$c/$path" ]; then
            sudo rm -rf "$c/$path"
        fi
    done
}

_add_repo() {
    if ! zypper lr --alias rifux.dev &>/dev/null; then    
        _log "[ i ] Adding home:rifux.dev repository"
        sudo zypper --gpg-auto-import-keys ar -f https://download.opensuse.org/repositories/home:/rifux.dev/openSUSE_Tumbleweed/home:rifux.dev.repo
        sudo zypper ref
    fi
}

_install_deps() {
    _log "[ i ] Installing dependencies from Tumbleweed repo"
    sudo zypper in --no-confirm axel blueprint-compiler bluez bluez-auto-enable-devices bluez-cups bluez-firmware brightnessctl cairomm-devel cairomm1_0-devel cargo cliphist cmake coreutils curl dart-sass ddcutil file-devel fish fontconfig foot fuzzel gammastep gdouros-symbola-fonts gjs gjs-devel gnome-bluetooth gnome-bluetooth gnome-bluetooth gnome-control-center gnome-keyring gobject-introspection gobject-introspection-devel gojq grim gtk-layer-shell-devel gtk3 gtk3-metatheme-adwaita gtk4-devel gtkmm3-devel gtksourceview-devel gtksourceviewmm-devel gtksourceviewmm3_0-devel hypridle hyprland hyprlang-devel jetbrains-mono-fonts kernel-firmware-bluetooth lato-fonts libadwaita-devel libcairomm-1_0-1 libcairomm-1_16-1 libdbusmenu-gtk3-4 libdbusmenu-gtk3-devel libdbusmenu-gtk4 libdrm-devel libgbm-devel libgnome-bluetooth-3_0-13 libgtksourceview-3_0-1 libgtksourceviewmm-3_0-0 libgtksourceviewmm-4_0-0 libjxl-devel libpulse-devel libqt5-qtwayland libsass-3_6_6-1 libsass-devel libsoup-devel libspng0-devel libtinyxml0 libtinyxml2-10 libwebp-devel libxdp-devel Mesa-libGLESv2-devel Mesa-libGLESv3-devel meson NetworkManager npm opi pam-devel pavucontrol playerctl polkit-gnome pugixml-devel python3-anyascii python3-base python3-build python3-gobject-devel python3-libsass python3-material-color-utilities-python python3-Pillow python3-pip python3-psutil python3-pywayland python3-regex python3-setuptools_scm python3-svglib python3-wheel qt5ct qt6-quickcontrols2-devel qt6-wayland qt6-waylandclient-devel qt6-waylandclient-private-devel qt6-widgets-devel ripgrep rsync scdoc sdbus-cpp-devel slurp starship swappy swww systemd-devel tesseract tesseract-data tinyxml-devel tinyxml2-devel typelib-1_0-Xdp-1_0 typelib-1_0-XdpGtk3-1_0 typelib-1_0-XdpGtk4-1_0 typescript unzip update-desktop-files upower wayland-protocols-devel webp-pixbuf-loader wf-recorder wget wireplumber wl-clipboard wl-clipboard xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-utils xrandr ydotool
    sudo zypper in -t pattern gnome
    
    _log "[ i ] Installing dependencies from opi"
    _log "[ ! ] Select 'yad' and then 'multimedia_proaudio' or 'Dead_Mozay' repo"
    read -p "[ ? ] Press 'Enter' to install 'yad' from opi."
    opi yad
}

_fetch_configs() {
    _log "[ i ] Fetching configs"
    cd "$t"
    git clone https://github.com/end-4/dots-hyprland && \
        cd dots-hyprland && \
        cp -r {.config,.local} "$HOME/"
}

_fetch_fonts() {
    _log "[ i ] Fetching fonts"
    cd "$t"
    git clone https://codeberg.org/rifux/end4-fonts
    sudo cp -r end4-fonts /usr/local/share/fonts
}

#_fetch_cursor() {# WIP}

_enable_ydotool() {
    _log "[ i ] Enabling ydotool"
    sudo systemctl daemon-reload
    sudo systemctl enable ydotoold
    sudo systemctl start ydotoold
    ln -sf /tmp/.ydotool_socket /run/user/$(id -u $(whoami))/.ydotool_socket
}

_install_hyprutils() {
    _log "[ i ] Installing hyprutils"
    cd "$t"
    git clone https://github.com/hyprwm/hyprutils.git && \
        cd hyprutils/
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`
    sudo cmake --install build
}

_install_hyprpicker() {
    _log "[ i ] Installing hyprpicker"
    cd "$t"
    git clone https://github.com/hyprwm/hyprpicker.git && \
        cd hyprpicker
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target hyprpicker -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    sudo cmake --install ./build
}

_install_hyprgraphics() {
	_log "[ i ] Installing hyprgraphics"
	cd "$t"
	git clone https://github.com/hyprwm/hyprgraphics && \
	        cd hyprgraphics/
	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
	sudo cmake --install build
}

_install_hyprwayland_scanner() {
    _log "[ i ] Installing hyprwayland-scanner"
    cd "$t"
    git clone https://github.com/hyprwm/hyprwayland-scanner.git
    cd hyprwayland-scanner
    cmake -DCMAKE_INSTALL_PREFIX=/usr -B build
    cmake --build build -j $(nproc)
    sudo cmake --install build
}

_install_hyprlock() {
    _log "[ i ] Installing hyprlock"
    cd "$t"
    git clone https://github.com/hyprwm/hyprlock.git
    cd hyprlock
    cmake --no-warn-unused-cli -DCMAKE_CXX_FLAGS="-L/usr/local/lib64 -lsdbus-c++" -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    sudo cmake --install build
}

_install_hyprland_qtutils() {
    _log "[ i ] Installing hyprland-qtutils"
    cd "$t"
    git clone https://github.com/hyprwm/hyprland-qtutils.git && \
        cd hyprland-qtutils
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
	sudo cmake --install build
}

_install_hyprland() {
    _log "[ i ] Installing Hyprland"
    cd "$t"
    sudo zypper in gcc-c++ git meson cmake "pkgconfig(cairo)" "pkgconfig(egl)" "pkgconfig(gbm)" "pkgconfig(gl)" "pkgconfig(glesv2)" "pkgconfig(libdrm)" "pkgconfig(libinput)" "pkgconfig(libseat)" "pkgconfig(libudev)" "pkgconfig(pango)" "pkgconfig(pangocairo)" "pkgconfig(pixman-1)" "pkgconfig(vulkan)" "pkgconfig(wayland-client)" "pkgconfig(wayland-protocols)" "pkgconfig(wayland-scanner)" "pkgconfig(wayland-server)" "pkgconfig(xcb)" "pkgconfig(xcb-icccm)" "pkgconfig(xcb-renderutil)" "pkgconfig(xkbcommon)" "pkgconfig(xwayland)" "pkgconfig(xcb-errors)" glslang-devel Mesa-libGLESv3-devel tomlplusplus-devel
    git clone --recursive https://github.com/hyprwm/Hyprland && \
        cd Hyprland
    make all && sudo make install
}

_install_wlogout() {
    _log "[ i ] Installing wlogout"
    cd "$t"
    git clone https://github.com/ArtsyMacaw/wlogout.git
    cd wlogout
    meson build
    ninja -C build
    sudo ninja -C build install
}

_install_anyrun() {
    _log "[ i ] Installing anyrun"
    cd "$t"
    git clone https://github.com/anyrun-org/anyrun.git
    cd anyrun
    cargo build --release
    cargo install --path anyrun/
    sudo cp "$HOME/.cargo/bin/anyrun" /usr/local/bin/
    mkdir -p ~/.config/anyrun/plugins
    cp target/release/*.so ~/.config/anyrun/plugins
    cp examples/config.ron ~/.config/anyrun/config.ron
}

_exec_manualinstaller() {
    _log "[ ! ] Now manual installer of end-4/dots will be started."
    read -p "[ ? ] Press 'Enter' to continue"
    cd "$t"
    cd dots-hyprland
    ./manual-install-helper.sh
}

# Temporary workaround for current issue with ags makes itself a strange broken look
_remove_transparency() {
    _file="$HOME/.config/ags/modules/sideright/centermodules/configure.js"

    sed -i -e \
        "s|                        ConfigToggle({|\/\*                        ConfigToggle({|g" \
        "$_file"
    sed -i -e \
        "s|console\.log(transparency)\;|console\.log(transparency)\;\*\/|g" \
        "$_file"
    sed -i -e \
        "s|                                execAsync(|\/\/                                execAsync(|g" \
        "$_file"
    sed -i -e \
        "s|                                    .then(execAsync(|\/\*                                    .then(execAsync(|g" \
        "$_file"
    sed -i -e \
        "s|                        HyprlandToggle({ icon: 'blur_on'|\*\/                        HyprlandToggle({ icon: 'blur_on'|g" \
        "$_file"
}

_program() {
    _cleanup
    mkdir -p "$t"
    _add_repo
    _install_deps
    _fetch_configs
    _fetch_fonts
    #_fetch_cursor   # Work in progress
    _enable_ydotool
    _install_hyprutils
    _install_hyprwayland_scanner
    _install_hyprpicker
    _install_hyprgraphics
    _install_hyprlock
    _install_hyprland_qtutils
    _install_wlogout
    _install_anyrun
    _exec_manualinstaller
    _remove_transparency
}

_program
