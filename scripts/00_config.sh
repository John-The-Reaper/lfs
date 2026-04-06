#!/bin/bash
# =============================================================================
# LFS 13.0-systemd — Configuration globale
# Adapté à la machine : Debian, disque /dev/sda, partition /dev/sda3
# =============================================================================

# --- Partition et montage ---
export LFS=/mnt/lfs
export LFS_DISK=/dev/sda
export LFS_PART=/dev/sda3

# --- Triplet de compilation croisée ---
export LFS_TGT=$(uname -m)-lfs-linux-gnu

# --- Parallélisme ---
export MAKEFLAGS="-j$(nproc)"
export TESTSUITEFLAGS="-j$(nproc)"

# --- Versions des paquets ---
BINUTILS_VER=2.46.0
GCC_VER=15.2.0
LINUX_VER=6.18.10
GLIBC_VER=2.43
GMP_VER=6.3.0
MPFR_VER=4.2.2
MPC_VER=1.3.1
M4_VER=1.4.21
NCURSES_VER=6.6
BASH_VER=5.3
COREUTILS_VER=9.10
DIFFUTILS_VER=3.12
FILE_VER=5.46
FINDUTILS_VER=4.10.0
GAWK_VER=5.3.2
GREP_VER=3.12
GZIP_VER=1.14
MAKE_VER=4.4.1
PATCH_VER=2.8
SED_VER=4.9
TAR_VER=1.35
XZ_VER=5.8.2
GETTEXT_VER=1.0
BISON_VER=3.8.2
PERL_VER=5.42.0
PYTHON_VER=3.14.3
TEXINFO_VER=7.2
UTIL_LINUX_VER=2.41.3
TZDATA_VER=2025c
MANPAGES_VER=6.17
IANA_ETC_VER=20260202
ZLIB_VER=1.3.2
BZIP2_VER=1.0.8

# --- Couleurs pour les logs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Vérifier que LFS est défini et monté
check_lfs() {
    [[ -z "$LFS" ]] && log_error "La variable LFS n'est pas définie !"
    mountpoint -q "$LFS" || log_error "$LFS n'est pas monté !"
    log_ok "LFS=$LFS monté."
}
