#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 5 : Outils additionnels dans le chroot
# DOIT être exécuté DEPUIS L'INTÉRIEUR du chroot
# (lancé automatiquement par 04_chroot_prep.sh ou manuellement depuis le chroot)
# Chapitre 7.7 à 7.13 du livre LFS
# =============================================================================
set -e

GETTEXT_VER=1.0
BISON_VER=3.8.2
PERL_VER=5.42.0
PYTHON_VER=3.14.3
TEXINFO_VER=7.2
UTIL_LINUX_VER=2.41.3

SRC=/sources
cd "$SRC"

log_info() { echo "[INFO] $*"; }
log_ok()   { echo "[OK]   $*"; }

build_pkg() { log_info "Construction de $2..."; tar -xf "$1"; cd "$2"; }
clean_pkg() { cd "$SRC"; rm -rf "$1"; log_ok "$1 installé."; }

# =============================================================================
# 7.7 — Gettext-1.0
# Seuls msgfmt, msgmerge, xgettext sont nécessaires à ce stade
# =============================================================================
build_gettext() {
    build_pkg "gettext-${GETTEXT_VER}.tar.xz" "gettext-${GETTEXT_VER}"
    ./configure --disable-shared
    make
    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
    clean_pkg "gettext-${GETTEXT_VER}"
}

# =============================================================================
# 7.8 — Bison-3.8.2
# =============================================================================
build_bison() {
    build_pkg "bison-${BISON_VER}.tar.xz" "bison-${BISON_VER}"
    ./configure --prefix=/usr \
                --docdir="/usr/share/doc/bison-${BISON_VER}"
    make
    make install
    clean_pkg "bison-${BISON_VER}"
}

# =============================================================================
# 7.9 — Perl-5.42.0
# =============================================================================
build_perl() {
    build_pkg "perl-${PERL_VER}.tar.xz" "perl-${PERL_VER}"
    sh Configure -des                                     \
                 -D prefix=/usr                          \
                 -D vendorprefix=/usr                    \
                 -D useshrplib                           \
                 -D privlib="/usr/lib/perl5/${PERL_VER}/core_perl"   \
                 -D archlib="/usr/lib/perl5/${PERL_VER}/core_perl"   \
                 -D sitelib="/usr/lib/perl5/${PERL_VER}/site_perl"   \
                 -D sitearch="/usr/lib/perl5/${PERL_VER}/site_perl"  \
                 -D vendorlib="/usr/lib/perl5/${PERL_VER}/vendor_perl" \
                 -D vendorarch="/usr/lib/perl5/${PERL_VER}/vendor_perl"
    make
    make install
    clean_pkg "perl-${PERL_VER}"
}

# =============================================================================
# 7.10 — Python-3.14.3
# =============================================================================
build_python() {
    build_pkg "Python-${PYTHON_VER}.tar.xz" "Python-${PYTHON_VER}"
    ./configure --prefix=/usr         \
                --enable-shared       \
                --without-ensurepip   \
                --without-static-libpython
    make
    make install
    clean_pkg "Python-${PYTHON_VER}"
}

# =============================================================================
# 7.11 — Texinfo-7.2
# =============================================================================
build_texinfo() {
    build_pkg "texinfo-${TEXINFO_VER}.tar.xz" "texinfo-${TEXINFO_VER}"
    ./configure --prefix=/usr
    make
    make install
    clean_pkg "texinfo-${TEXINFO_VER}"
}

# =============================================================================
# 7.12 — Util-linux-2.41.3
# =============================================================================
build_util_linux() {
    build_pkg "util-linux-${UTIL_LINUX_VER}.tar.xz" "util-linux-${UTIL_LINUX_VER}"
    mkdir -pv /var/lib/hwclock
    ./configure --libdir=/usr/lib             \
                --runstatedir=/run            \
                --disable-chfn-chsh          \
                --disable-login              \
                --disable-nologin            \
                --disable-su                 \
                --disable-setpriv            \
                --disable-runuser            \
                --disable-pylibmount         \
                --disable-static             \
                --disable-liblastlog2        \
                --without-python             \
                ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --docdir="/usr/share/doc/util-linux-${UTIL_LINUX_VER}"
    make
    make install
    clean_pkg "util-linux-${UTIL_LINUX_VER}"
}

# =============================================================================
# 7.13 — Nettoyage des outils temporaires
# =============================================================================
cleanup_temp() {
    log_info "Nettoyage des fichiers temporaires..."
    rm -rf /usr/share/{info,man,doc}/*
    find /usr/{lib,libexec} -name \*.la -delete
    rm -rf /tools
    log_ok "Nettoyage terminé. Système temporaire (~3 Go sans /tools)."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 5 : Outils chroot (Chapitre 7.7-7.13) ==="
    build_gettext
    build_bison
    build_perl
    build_python
    build_texinfo
    build_util_linux
    cleanup_temp
    log_ok "=== Phase 5 terminée — Système temporaire complet ==="
    log_info "Lancez maintenant (depuis le chroot) : bash /sources/scripts/06_system_build.sh"
}

main "$@"
