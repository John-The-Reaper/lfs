#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 4 : Préparation et entrée dans le chroot
# À exécuter en tant que ROOT sur la machine hôte
# Chapitre 7.1 à 7.6 du livre LFS
# =============================================================================
set -e
source "$(dirname "$0")/00_config.sh"

[[ $EUID -ne 0 ]] && log_error "Ce script doit être exécuté en tant que root."
check_lfs

# =============================================================================
# 7.2 — Changement de propriétaire (root:root)
# =============================================================================
change_ownership() {
    log_info "Transfert de propriété vers root:root..."
    chown --from lfs -R root:root "$LFS"/{usr,lib,var,etc,bin,sbin,tools,sources}
    case $(uname -m) in
        x86_64) chown --from lfs -R root:root "$LFS/lib64" ;;
    esac
    log_ok "Propriété transférée."
}

# =============================================================================
# 7.3 — Montage des systèmes de fichiers virtuels du noyau
# =============================================================================
mount_vfs() {
    log_info "Montage des systèmes de fichiers virtuels..."
    mkdir -pv "$LFS"/{dev,proc,sys,run}

    # /dev (bind depuis l'hôte)
    if ! mountpoint -q "$LFS/dev"; then
        mount -v --bind /dev "$LFS/dev"
    fi

    # devpts
    if ! mountpoint -q "$LFS/dev/pts"; then
        mount -vt devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
    fi

    # proc
    if ! mountpoint -q "$LFS/proc"; then
        mount -vt proc proc "$LFS/proc"
    fi

    # sysfs
    if ! mountpoint -q "$LFS/sys"; then
        mount -vt sysfs sysfs "$LFS/sys"
    fi

    # tmpfs pour /run
    if ! mountpoint -q "$LFS/run"; then
        mount -vt tmpfs tmpfs "$LFS/run"
    fi

    # /dev/shm
    if [ -h "$LFS/dev/shm" ]; then
        install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
    else
        if ! mountpoint -q "$LFS/dev/shm"; then
            mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
        fi
    fi

    log_ok "Systèmes de fichiers virtuels montés."
}

# Démonter proprement (utile pour backup ou redémarrage)
umount_vfs() {
    log_info "Démontage des systèmes de fichiers virtuels..."
    mountpoint -q "$LFS/dev/shm" && umount "$LFS/dev/shm"
    umount "$LFS/dev/pts" 2>/dev/null || true
    umount "$LFS"/{sys,proc,run,dev} 2>/dev/null || true
    log_ok "Démontage terminé."
}

# =============================================================================
# Lancer un script DANS le chroot
# =============================================================================
run_in_chroot() {
    local script_path="$1"
    log_info "Exécution de $script_path dans le chroot..."
    chroot "$LFS" /usr/bin/env -i     \
        HOME=/root                    \
        TERM="$TERM"                  \
        PS1='(lfs chroot) \u:\w\$ '   \
        PATH=/usr/bin:/usr/sbin       \
        MAKEFLAGS="-j$(nproc)"        \
        TESTSUITEFLAGS="-j$(nproc)"   \
        /bin/bash "$script_path"
}

# =============================================================================
# 7.4 — Entrée interactive dans le chroot (pour débogage)
# =============================================================================
enter_chroot() {
    log_info "Entrée dans le chroot LFS..."
    chroot "$LFS" /usr/bin/env -i     \
        HOME=/root                    \
        TERM="$TERM"                  \
        PS1='(lfs chroot) \u:\w\$ '   \
        PATH=/usr/bin:/usr/sbin       \
        MAKEFLAGS="-j$(nproc)"        \
        TESTSUITEFLAGS="-j$(nproc)"   \
        /bin/bash --login
}

# =============================================================================
# 7.5 — Création de la structure FHS dans le chroot
# 7.6 — Fichiers essentiels et liens symboliques
# Ces commandes s'exécutent via heredoc dans le chroot
# =============================================================================
setup_chroot_fs() {
    log_info "Création de la structure FHS et des fichiers essentiels..."
    chroot "$LFS" /usr/bin/env -i   \
        HOME=/root TERM="$TERM"     \
        PATH=/usr/bin:/usr/sbin     \
        /bin/bash --login << 'CHROOT_EOF'

set -e

# --- 7.5 Répertoires ---
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

# --- 7.6 Fichiers essentiels ---
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << "EOF"
127.0.0.1  localhost
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal:x:23:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# Utilisateur de test temporaire
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

# Fichiers de log
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

echo "Structure FHS créée avec succès."
CHROOT_EOF
    log_ok "Structure FHS et fichiers essentiels créés."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    case "${1:-setup}" in
        setup)
            log_info "=== Phase 4 : Préparation du chroot ==="
            change_ownership
            mount_vfs
            setup_chroot_fs
            # Copier les scripts dans le chroot pour y être accessibles
            SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
            mkdir -pv "$LFS/sources/scripts"
            cp -v "$SCRIPTS_DIR"/*.sh "$LFS/sources/scripts/"
            log_ok "Scripts copiés dans $LFS/sources/scripts/"
            log_ok "=== Phase 4 terminée ==="
            log_info "Entrez dans le chroot puis lancez le script :"
            log_info "  bash $0 enter"
            log_info "  (depuis le chroot) bash /sources/scripts/05_chroot_tools.sh"
            ;;
        mount)   mount_vfs ;;
        umount)  umount_vfs ;;
        enter)   mount_vfs; enter_chroot ;;
        *)
            echo "Usage: $0 [setup|mount|umount|enter]"
            ;;
    esac
}

main "$@"
