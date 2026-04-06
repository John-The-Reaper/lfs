#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 7 : Configuration du système
# DOIT être exécuté DEPUIS L'INTÉRIEUR du chroot
# Chapitre 9 du livre LFS (systemd variant)
# =============================================================================
set -e

# --- Paramètres à adapter ---
LFS_HOSTNAME="${LFS_HOSTNAME:-lfs}"
LFS_TIMEZONE="${LFS_TIMEZONE:-Europe/Paris}"
LFS_LOCALE="${LFS_LOCALE:-fr_FR.UTF-8}"
LFS_LANG="${LFS_LANG:-fr_FR.UTF-8}"
LFS_KEYMAP="${LFS_KEYMAP:-fr-latin9}"
LFS_FONT="${LFS_FONT:-Lat2-Terminus16}"

# Réseau (adapter selon l'interface et la topologie)
NET_INTERFACE="${NET_INTERFACE:-eth0}"
NET_DHCP="${NET_DHCP:-true}"        # true=DHCP, false=statique
NET_ADDR="${NET_ADDR:-192.168.1.100/24}"
NET_GW="${NET_GW:-192.168.1.1}"
NET_DNS="${NET_DNS:-192.168.1.1}"

# --- Helpers ---
log_ok()   { echo -e "\e[32m[OK]\e[0m  $*"; }
log_info() { echo -e "\e[34m[..]\e[0m  $*"; }
log_err()  { echo -e "\e[31m[ERR]\e[0m $*" >&2; }

# =============================================================================
# 9.2 — Configuration réseau (systemd-networkd)
# =============================================================================
setup_network() {
    log_info "Configuration réseau systemd-networkd..."

    if [ "$NET_DHCP" = "true" ]; then
        cat > /etc/systemd/network/10-eth-dhcp.network << EOF
[Match]
Name=${NET_INTERFACE}

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true
EOF
    else
        cat > /etc/systemd/network/10-eth-static.network << EOF
[Match]
Name=${NET_INTERFACE}

[Network]
Address=${NET_ADDR}
Gateway=${NET_GW}
DNS=${NET_DNS}
EOF
    fi

    # systemd-resolved : créer le lien symbolique
    ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf

    log_ok "Réseau configuré."
}

# =============================================================================
# 9.2.3 — Hostname
# =============================================================================
setup_hostname() {
    log_info "Hostname : ${LFS_HOSTNAME}"
    echo "${LFS_HOSTNAME}" > /etc/hostname
    log_ok "Hostname défini."
}

# =============================================================================
# 9.2.4 — /etc/hosts
# =============================================================================
setup_hosts() {
    log_info "Création de /etc/hosts..."
    cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1  localhost
127.0.1.1  lfs
::1        localhost ip6-localhost ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters

# End /etc/hosts
EOF
    # Injecter le hostname réel
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1  ${LFS_HOSTNAME}/" /etc/hosts
    log_ok "/etc/hosts configuré."
}

# =============================================================================
# 9.5 — Horloge système (/etc/adjtime)
# =============================================================================
setup_clock() {
    log_info "Configuration horloge (UTC)..."
    cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
UTC
EOF
    # Fuseau horaire
    ln -sfv /usr/share/zoneinfo/${LFS_TIMEZONE} /etc/localtime
    log_ok "Horloge configurée (UTC, ${LFS_TIMEZONE})."
}

# =============================================================================
# 9.6 — Console virtuelle (/etc/vconsole.conf)
# =============================================================================
setup_console() {
    log_info "Configuration console..."
    cat > /etc/vconsole.conf << EOF
KEYMAP=${LFS_KEYMAP}
FONT=${LFS_FONT}
EOF
    log_ok "Console configurée."
}

# =============================================================================
# 9.7 — Locale (/etc/locale.conf)
# =============================================================================
setup_locale() {
    log_info "Configuration locale..."
    cat > /etc/locale.conf << EOF
LANG=${LFS_LANG}
EOF
    log_ok "Locale configurée (${LFS_LANG})."
}

# =============================================================================
# 9.8 — /etc/inputrc
# =============================================================================
setup_inputrc() {
    log_info "Création de /etc/inputrc..."
    cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
#"\eOD": backward-word
"\e0C": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
    log_ok "/etc/inputrc créé."
}

# =============================================================================
# 9.9 — /etc/shells
# =============================================================================
setup_shells() {
    log_info "Création de /etc/shells..."
    cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
    log_ok "/etc/shells créé."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 7 : Configuration du système (Chapitre 9) ==="

    setup_hostname
    setup_hosts
    setup_network
    setup_clock
    setup_console
    setup_locale
    setup_inputrc
    setup_shells

    log_ok "=== Phase 7 terminée — Configuration système complète ==="
    log_info "Lancez maintenant : bash /sources/scripts/08_kernel_boot.sh"
}

main "$@"
