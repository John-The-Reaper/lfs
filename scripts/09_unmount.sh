#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 9 : Démontage des systèmes de fichiers virtuels
# DOIT être exécuté depuis l'HÔTE (pas dans le chroot) — §11.3
# =============================================================================
set -e

export LFS=${LFS:-/mnt/lfs}

log_ok()   { echo -e "\e[32m[OK]\e[0m  $*"; }
log_info() { echo -e "\e[34m[..]\e[0m  $*"; }

log_info "Démontage des systèmes de fichiers virtuels LFS..."

umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm || true
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

# Démontage de la partition LFS elle-même
umount -v $LFS

log_ok "Tous les systèmes de fichiers démontés."
log_info "Vous pouvez maintenant redémarrer : reboot"
