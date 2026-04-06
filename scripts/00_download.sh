#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 0 : Téléchargement de toutes les sources
# À exécuter en tant que ROOT (ou lfs) sur la machine hôte
# URLs extraites directement du livre LFS-BOOK-13.0-SYSD.pdf (Chapitre 3)
# =============================================================================
set -e
source "$(dirname "$0")/00_config.sh"

check_lfs

DEST="$LFS/sources"
mkdir -pv "$DEST"
chmod -v a+wt "$DEST"
cd "$DEST"

log_info() { echo -e "\e[34m[..]\e[0m  $*"; }
log_ok()   { echo -e "\e[32m[OK]\e[0m  $*"; }
log_warn() { echo -e "\e[33m[!!]\e[0m  $*"; }

# Télécharge un fichier seulement s'il n'existe pas déjà
dl() {
    local url="$1"
    local file="${2:-$(basename "$url")}"
    if [ -f "$DEST/$file" ]; then
        log_ok "Déjà présent : $file"
    else
        log_info "Téléchargement : $file"
        wget -q --show-progress -O "$DEST/$file" "$url" || {
            log_warn "ÉCHEC : $url"
            rm -f "$DEST/$file"
        }
    fi
}

GNU="https://ftpmirror.gnu.org"
GH="https://github.com"

# =============================================================================
# Paquets sources (§3.2)
# =============================================================================
dl "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.xz"
dl "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz"
dl "$GNU/autoconf/autoconf-2.72.tar.xz"
dl "$GNU/automake/automake-1.18.1.tar.xz"
dl "$GNU/bash/bash-5.3.tar.gz"
dl "$GH/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz"
dl "https://sourceware.org/pub/binutils/releases/binutils-2.46.0.tar.xz"
dl "$GNU/bison/bison-3.8.2.tar.xz"
dl "https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
dl "$GNU/coreutils/coreutils-9.10.tar.xz"
dl "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz"
dl "$GNU/dejagnu/dejagnu-1.6.3.tar.gz"
dl "$GNU/diffutils/diffutils-3.12.tar.xz"
dl "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz"
dl "https://sourceware.org/ftp/elfutils/0.194/elfutils-0.194.tar.bz2"
dl "$GH/libexpat/libexpat/releases/download/R_2_7_4/expat-2.7.4.tar.xz"
dl "https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz"
dl "https://astron.com/pub/file/file-5.46.tar.gz"
dl "$GNU/findutils/findutils-4.10.0.tar.xz"
dl "$GH/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz"
dl "https://pypi.org/packages/source/f/flit-core/flit-core-3.12.0.tar.gz"
dl "$GNU/gawk/gawk-5.3.2.tar.xz"
dl "$GNU/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz"
dl "$GNU/gdbm/gdbm-1.26.tar.gz"
dl "$GNU/gettext/gettext-1.0.tar.xz"
dl "$GNU/glibc/glibc-2.43.tar.xz"
dl "$GNU/gmp/gmp-6.3.0.tar.xz"
dl "$GNU/gperf/gperf-3.3.tar.gz"
dl "$GNU/grep/grep-3.12.tar.xz"
dl "$GNU/groff/groff-1.23.0.tar.gz"
dl "$GNU/grub/grub-2.14.tar.xz"
dl "$GNU/gzip/gzip-1.14.tar.xz"
dl "$GH/Mic92/iana-etc/releases/download/20260202/iana-etc-20260202.tar.gz"
dl "$GNU/inetutils/inetutils-2.7.tar.gz"
dl "https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz"
dl "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.18.0.tar.xz"
dl "https://pypi.org/packages/source/J/Jinja2/Jinja2-3.1.6.tar.gz"
dl "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.9.0.tar.xz"
dl "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz"
dl "https://www.greenwoodsoftware.com/less/less-692.tar.gz"
dl "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.77.tar.xz"
dl "$GH/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz"
dl "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz"
dl "$GNU/libtool/libtool-2.5.4.tar.xz"
dl "$GH/besser82/libxcrypt/releases/download/v4.5.2/libxcrypt-4.5.2.tar.xz"
dl "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz"
dl "$GH/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz"
dl "$GNU/m4/m4-1.4.21.tar.xz"
dl "$GNU/make/make-4.4.1.tar.gz"
dl "https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz"
dl "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.17.tar.xz"
dl "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-3.0.3.tar.gz"
dl "$GH/mesonbuild/meson/releases/download/1.10.1/meson-1.10.1.tar.gz"
dl "$GNU/mpc/mpc-1.3.1.tar.gz"
dl "$GNU/mpfr/mpfr-4.2.2.tar.xz"
dl "https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz"
dl "$GH/ninja-build/ninja/archive/v1.13.2/ninja-1.13.2.tar.gz"
dl "$GH/openssl/openssl/releases/download/openssl-3.6.1/openssl-3.6.1.tar.gz"
dl "https://files.pythonhosted.org/packages/source/p/packaging/packaging-26.0.tar.gz"
dl "$GNU/patch/patch-2.8.tar.xz"
dl "$GH/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.bz2"
dl "https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz"
dl "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz"
dl "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.6.tar.xz"
dl "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz"
dl "https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tar.xz"
dl "$GNU/readline/readline-8.3.tar.gz"
dl "$GNU/sed/sed-4.9.tar.xz"
dl "https://files.pythonhosted.org/packages/source/s/setuptools/setuptools-82.0.0.tar.gz"
dl "$GH/shadow-maint/shadow/releases/download/4.19.3/shadow-4.19.3.tar.xz"
dl "https://sqlite.org/2026/sqlite-autoconf-3510200.tar.gz"
dl "https://anduin.linuxfromscratch.org/LFS/sqlite-doc-3510200.tar.xz"
dl "$GH/systemd/systemd/archive/v259.1/systemd-259.1.tar.gz"
dl "https://anduin.linuxfromscratch.org/LFS/systemd-man-pages-259.1.tar.xz"
dl "$GNU/tar/tar-1.35.tar.xz"
dl "https://downloads.sourceforge.net/tcl/tcl8.6.17-src.tar.gz"
dl "$GNU/texinfo/texinfo-7.2.tar.xz"
dl "https://www.iana.org/time-zones/repository/releases/tzdata2025c.tar.gz"
dl "https://www.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.3.tar.xz"
dl "$GH/vim/vim/archive/v9.2.0078/vim-9.2.0078.tar.gz"
dl "https://files.pythonhosted.org/packages/source/w/wheel/wheel-0.46.3.tar.gz"
dl "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz"
dl "$GH/tukaani-project/xz/releases/download/v5.8.2/xz-5.8.2.tar.xz"
dl "https://zlib.net/fossils/zlib-1.3.2.tar.gz"
dl "$GH/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz"

# =============================================================================
# Patches (§3.3)
# =============================================================================
LFS_PATCHES="https://www.linuxfromscratch.org/patches/lfs/13.0"
dl "$LFS_PATCHES/bzip2-1.0.8-install_docs-1.patch"
dl "$LFS_PATCHES/coreutils-9.10-i18n-1.patch"
dl "$LFS_PATCHES/expect-5.45.4-gcc15-1.patch"
dl "$LFS_PATCHES/glibc-2.43-fhs-1.patch" "glibc-fhs-1.patch"
dl "$LFS_PATCHES/kbd-2.9.0-backspace-1.patch"

# =============================================================================
# Vérification finale
# =============================================================================
echo
log_info "Vérification du contenu de $DEST ..."
TOTAL=$(find "$DEST" -maxdepth 1 -type f | wc -l)
log_ok "$TOTAL fichiers présents dans $DEST"
log_info "Espace utilisé : $(du -sh "$DEST" | cut -f1)"
log_info "Pour vérifier les checksums, comparer avec le md5sums du livre LFS."
