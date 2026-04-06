#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 8 : Kernel + Bootloader
# DOIT être exécuté DEPUIS L'INTÉRIEUR du chroot
# Chapitres 10 et 11 du livre LFS (systemd variant)
# =============================================================================
set -e

# --- Paramètres à adapter selon votre matériel ---
# Disque et partitions
ROOT_DEV="${ROOT_DEV:-/dev/sda3}"      # partition racine LFS (sda3 dans notre setup)
ROOT_FS="${ROOT_FS:-ext4}"
GRUB_DISK="${GRUB_DISK:-/dev/sda}"     # disque cible pour GRUB (MBR)
GRUB_PART_NUM="${GRUB_PART_NUM:-3}"    # numéro de partition root pour grub.cfg

# Kernel
KERNEL_VER="6.18.10"
LFS_VERSION="13.0-systemd"

SRC=/sources

# --- Helpers ---
log_ok()   { echo -e "\e[32m[OK]\e[0m  $*"; }
log_info() { echo -e "\e[34m[..]\e[0m  $*"; }
log_err()  { echo -e "\e[31m[ERR]\e[0m $*" >&2; }

# =============================================================================
# 10.2 — /etc/fstab
# =============================================================================
setup_fstab() {
    log_info "Création de /etc/fstab..."
    cat > /etc/fstab << EOF
# Begin /etc/fstab

# file system    mount-point  type    options            dump  fsck order
${ROOT_DEV}      /            ${ROOT_FS}  defaults           1     1
#/dev/sdaX       swap         swap    pri=1              0     0

# proc et sysfs sont montés par systemd automatiquement

# End /etc/fstab
EOF
    log_ok "/etc/fstab créé."
}

# =============================================================================
# 10.3 — Compilation du kernel Linux ${KERNEL_VER}
# =============================================================================
build_kernel() {
    log_info "Compilation du kernel Linux ${KERNEL_VER}..."

    cd ${SRC}
    tar -xf linux-${KERNEL_VER}.tar.xz
    cd linux-${KERNEL_VER}

    # Nettoyage
    make mrproper

    # Configuration : utiliser defconfig + personnalisation manuelle
    # Pour une VM (VirtualBox/QEMU), make defconfig suffit généralement.
    # Décommentez make menuconfig si vous souhaitez configurer interactivement.
    make defconfig
    # make menuconfig

    # Compilation (utilise tous les cœurs disponibles)
    make -j$(nproc)

    # Installation des modules
    make modules_install

    # Copie du kernel et des fichiers associés dans /boot
    install -v -m755 arch/x86/boot/bzImage \
        /boot/vmlinuz-${KERNEL_VER}-lfs-${LFS_VERSION}
    install -v -m644 System.map \
        /boot/System.map-${KERNEL_VER}
    install -v -m644 .config \
        /boot/config-${KERNEL_VER}

    # Documentation (optionnel)
    install -d /usr/share/doc/linux-${KERNEL_VER}
    cp -r Documentation -T /usr/share/doc/linux-${KERNEL_VER}

    # Corriger les permissions des sources
    chown -R 0:0 /usr/src/linux-${KERNEL_VER} 2>/dev/null || true

    cd ${SRC}
    rm -rf linux-${KERNEL_VER}
    log_ok "Kernel compilé et installé."
}

# =============================================================================
# 10.3.2 — Configuration du chargement des modules USB
# =============================================================================
setup_modprobe() {
    log_info "Configuration modprobe USB..."
    install -v -m755 -d /etc/modprobe.d
    cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ehci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
    log_ok "modprobe.d/usb.conf créé."
}

# =============================================================================
# 10.4 — Installation de GRUB
# =============================================================================
install_grub() {
    log_info "Installation de GRUB sur ${GRUB_DISK}..."
    grub-install ${GRUB_DISK}
    log_ok "GRUB installé."
}

# =============================================================================
# 10.4.4 — Fichier de configuration GRUB
# =============================================================================
setup_grub_cfg() {
    log_info "Création de /boot/grub/grub.cfg..."
    install -d /boot/grub
    cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_msdos
insmod ext2
set root=(hd0,${GRUB_PART_NUM})

menuentry "GNU/Linux, Linux ${KERNEL_VER}-lfs-${LFS_VERSION}" {
    linux   /boot/vmlinuz-${KERNEL_VER}-lfs-${LFS_VERSION} root=${ROOT_DEV} ro
}
# End /boot/grub/grub.cfg
EOF
    log_ok "/boot/grub/grub.cfg créé."
}

# =============================================================================
# 11.1 — Fichiers d'identification de la distribution
# =============================================================================
setup_release_files() {
    log_info "Création des fichiers de release..."
    echo "${LFS_VERSION}" > /etc/lfs-release

    cat > /etc/lsb-release << EOF
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="${LFS_VERSION}"
DISTRIB_CODENAME="LFS"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

    cat > /etc/os-release << EOF
NAME="Linux From Scratch"
VERSION="${LFS_VERSION}"
ID=lfs
PRETTY_NAME="Linux From Scratch ${LFS_VERSION}"
VERSION_CODENAME="LFS"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF
    log_ok "Fichiers de release créés."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 8 : Kernel + Bootloader (Chapitres 10–11) ==="
    log_info "Disque cible : ${GRUB_DISK}  |  Partition root : ${ROOT_DEV}"
    log_info "Kernel : ${KERNEL_VER}  |  LFS : ${LFS_VERSION}"
    echo

    setup_fstab
    build_kernel
    setup_modprobe
    install_grub
    setup_grub_cfg
    setup_release_files

    log_ok "=== Phase 8 terminée — Système LFS prêt au démarrage ==="
    echo
    log_info "Quittez le chroot (exit), puis depuis l'hôte :"
    log_info "  bash /mnt/lfs/sources/scripts/09_unmount.sh"
    log_info "  reboot"
}

main "$@"
