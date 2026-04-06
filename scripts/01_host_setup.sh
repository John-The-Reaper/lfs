#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 1 : Préparation de la machine hôte
# À exécuter en tant que ROOT sur la machine hôte Debian
# Chapitres 2, 3, 4 du livre LFS
# =============================================================================
set -e
source "$(dirname "$0")/00_config.sh"

# --- Vérifications préliminaires ---
[[ $EUID -ne 0 ]] && log_error "Ce script doit être exécuté en tant que root."

# =============================================================================
# 2.1 — Installation des dépendances hôte
# =============================================================================
install_host_deps() {
    log_info "Installation des dépendances hôte..."
    apt-get update -y
    apt-get install -y \
        build-essential \
        binutils \
        bison \
        gawk \
        m4 \
        patch \
        texinfo \
        wget \
        xz-utils \
        perl \
        python3 \
        flex \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev

    # Lien symbolique sh -> bash
    if [[ "$(readlink /bin/sh)" != "bash" ]]; then
        ln -sfv bash /bin/sh
        log_ok "/bin/sh -> bash"
    fi

    # Vérifier les alias requis
    [[ "$(awk --version 2>&1 | head -1)" == *GNU* ]] || log_warn "awk n'est pas GNU awk !"
    log_ok "Dépendances hôte installées."
}

# =============================================================================
# 2.2 — Partitionnement et montage
# Note : la partition /dev/sda3 doit avoir été créée manuellement avec cfdisk
# Ce script se charge uniquement de formater (si demandé) et monter.
# =============================================================================
setup_partition() {
    log_info "Configuration de la partition LFS..."

    if ! blkid "$LFS_PART" | grep -q ext4; then
        log_warn "La partition $LFS_PART ne semble pas être ext4."
        read -rp "Formater $LFS_PART en ext4 ? [o/N] " rep
        if [[ "$rep" =~ ^[oO]$ ]]; then
            mkfs.ext4 -v "$LFS_PART"
            log_ok "$LFS_PART formatée en ext4."
        fi
    fi

    mkdir -pv "$LFS"
    if ! mountpoint -q "$LFS"; then
        mount -v -t ext4 "$LFS_PART" "$LFS"
        log_ok "$LFS_PART montée sur $LFS"
    else
        log_ok "$LFS déjà montée."
    fi
}

# =============================================================================
# 2.3 — Rendre le montage persistant (/etc/fstab)
# =============================================================================
setup_fstab() {
    if ! grep -q "$LFS_PART" /etc/fstab; then
        echo "$LFS_PART  $LFS  ext4  defaults  1  1" >> /etc/fstab
        log_ok "Entrée ajoutée dans /etc/fstab."
    fi
}

# =============================================================================
# 4.2 — Création de la structure de répertoires LFS
# =============================================================================
create_lfs_dirs() {
    log_info "Création de la structure de répertoires LFS..."
    check_lfs

    mkdir -pv "$LFS"/{etc,var} "$LFS"/usr/{bin,lib,sbin}
    mkdir -pv "$LFS"/sources
    chmod -v a+wt "$LFS"/sources  # sticky bit

    for i in bin lib sbin; do
        ln -sfv "usr/$i" "$LFS/$i" 2>/dev/null || true
    done

    case $(uname -m) in
        x86_64) mkdir -pv "$LFS"/lib64 ;;
    esac

    mkdir -pv "$LFS"/tools
    log_ok "Structure de répertoires créée."
}

# =============================================================================
# 4.3 — Création de l'utilisateur lfs
# =============================================================================
create_lfs_user() {
    log_info "Création de l'utilisateur lfs..."

    if ! getent group lfs &>/dev/null; then
        groupadd lfs
    fi
    if ! id lfs &>/dev/null; then
        useradd -s /bin/bash -g lfs -m -k /dev/null lfs
        echo "lfs:lfs" | chpasswd
        log_ok "Utilisateur lfs créé (mot de passe: lfs)."
    else
        log_ok "Utilisateur lfs existe déjà."
    fi

    chown -v lfs "$LFS"/{usr{,/*},lib,var,etc,bin,sbin,tools,sources}
    case $(uname -m) in
        x86_64) chown -v lfs "$LFS"/lib64 ;;
    esac
    log_ok "Permissions assignées à lfs."
}

# =============================================================================
# 4.4 — Configuration de l'environnement bash de lfs
# =============================================================================
setup_lfs_env() {
    log_info "Configuration de l'environnement bash pour lfs..."

    cat > /home/lfs/.bash_profile << 'EOF'
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

    cat > /home/lfs/.bashrc << EOF
set +h
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:\$PATH; fi
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS="-j\$(nproc)"
export TESTSUITEFLAGS="-j\$(nproc)"
EOF

    chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
    log_ok "Environnement bash lfs configuré."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 1 : Préparation de la machine hôte ==="
    install_host_deps
    setup_partition
    setup_fstab
    create_lfs_dirs
    create_lfs_user
    setup_lfs_env
    log_ok "=== Phase 1 terminée. Lancez maintenant scripts/02_toolchain.sh en tant que lfs ==="
    log_info "Commande : su - lfs -c 'bash $PWD/scripts/02_toolchain.sh'"
}

main "$@"
