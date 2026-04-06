#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 3 : Outils temporaires croisés
# À exécuter en tant qu'utilisateur LFS (su - lfs)
# Chapitre 6 du livre LFS
# =============================================================================
set -e
source "$(dirname "$0")/00_config.sh"

[[ "$(whoami)" != "lfs" ]] && log_error "Ce script doit être exécuté en tant que lfs."
check_lfs

SRC="$LFS/sources"
cd "$SRC"

build_pkg() {
    log_info "Construction de $2..."
    tar -xf "$1"
    cd "$2"
}

clean_pkg() {
    cd "$SRC"
    rm -rf "$1"
    log_ok "$1 installé."
}

# =============================================================================
# 6.2 — M4-1.4.21
# =============================================================================
build_m4() {
    build_pkg "m4-${M4_VER}.tar.xz" "m4-${M4_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "m4-${M4_VER}"
}

# =============================================================================
# 6.3 — Ncurses-6.6
# =============================================================================
build_ncurses() {
    build_pkg "ncurses-${NCURSES_VER}.tar.gz" "ncurses-${NCURSES_VER}"

    # Étape 1 : construire tic pour le système hôte
    mkdir build
    pushd build
        ../configure --prefix="$LFS/tools" AWK=gawk
        make -C include
        make -C progs tic
        install progs/tic "$LFS/tools/bin"
    popd

    # Étape 2 : Ncurses pour LFS
    ./configure --prefix=/usr               \
                --host="$LFS_TGT"           \
                --build="$(./config.guess)" \
                --mandir=/usr/share/man     \
                --with-manpage-format=normal \
                --with-shared               \
                --without-normal            \
                --with-cxx-shared           \
                --without-debug             \
                --without-ada               \
                --disable-stripping         \
                AWK=gawk
    make
    make DESTDIR="$LFS" install

    ln -sv libncursesw.so "$LFS/usr/lib/libncurses.so"
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"
    clean_pkg "ncurses-${NCURSES_VER}"
}

# =============================================================================
# 6.4 — Bash-5.3
# =============================================================================
build_bash() {
    build_pkg "bash-${BASH_VER}.tar.gz" "bash-${BASH_VER}"
    ./configure --prefix=/usr                       \
                --build="$(sh support/config.guess)" \
                --host="$LFS_TGT"                   \
                --without-bash-malloc
    make
    make DESTDIR="$LFS" install
    ln -sv bash "$LFS/bin/sh"
    clean_pkg "bash-${BASH_VER}"
}

# =============================================================================
# 6.5 — Coreutils-9.10
# =============================================================================
build_coreutils() {
    build_pkg "coreutils-${COREUTILS_VER}.tar.xz" "coreutils-${COREUTILS_VER}"
    ./configure --prefix=/usr                       \
                --host="$LFS_TGT"                   \
                --build="$(build-aux/config.guess)" \
                --enable-install-program=hostname   \
                --enable-no-install-program=kill,uptime
    make
    make DESTDIR="$LFS" install

    mv -v "$LFS/usr/bin/chroot"              "$LFS/usr/sbin"
    mkdir -pv "$LFS/usr/share/man/man8"
    mv -v "$LFS/usr/share/man/man1/chroot.1" "$LFS/usr/share/man/man8/chroot.8"
    sed -i 's/"1"/"8"/' "$LFS/usr/share/man/man8/chroot.8"
    clean_pkg "coreutils-${COREUTILS_VER}"
}

# =============================================================================
# 6.6 — Diffutils-3.12
# =============================================================================
build_diffutils() {
    build_pkg "diffutils-${DIFFUTILS_VER}.tar.xz" "diffutils-${DIFFUTILS_VER}"
    ./configure --prefix=/usr             \
                --host="$LFS_TGT"         \
                gl_cv_func_strcasecmp_works=y \
                --build="$(./build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "diffutils-${DIFFUTILS_VER}"
}

# =============================================================================
# 6.7 — File-5.46
# =============================================================================
build_file() {
    build_pkg "file-${FILE_VER}.tar.gz" "file-${FILE_VER}"

    mkdir build && pushd build
        ../configure --disable-bzlib      \
                     --disable-libseccomp \
                     --disable-xzlib     \
                     --disable-zlib
        make
    popd

    ./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
    make FILE_COMPILE="$(pwd)/build/src/file"
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/libmagic.la"
    clean_pkg "file-${FILE_VER}"
}

# =============================================================================
# 6.8 — Findutils-4.10.0
# =============================================================================
build_findutils() {
    build_pkg "findutils-${FINDUTILS_VER}.tar.xz" "findutils-${FINDUTILS_VER}"
    ./configure --prefix=/usr                    \
                --localstatedir=/var/lib/locate  \
                --host="$LFS_TGT"               \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "findutils-${FINDUTILS_VER}"
}

# =============================================================================
# 6.9 — Gawk-5.3.2
# =============================================================================
build_gawk() {
    build_pkg "gawk-${GAWK_VER}.tar.xz" "gawk-${GAWK_VER}"
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "gawk-${GAWK_VER}"
}

# =============================================================================
# 6.10 — Grep-3.12
# =============================================================================
build_grep() {
    build_pkg "grep-${GREP_VER}.tar.xz" "grep-${GREP_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(./build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "grep-${GREP_VER}"
}

# =============================================================================
# 6.11 — Gzip-1.14
# =============================================================================
build_gzip() {
    build_pkg "gzip-${GZIP_VER}.tar.xz" "gzip-${GZIP_VER}"
    ./configure --prefix=/usr --host="$LFS_TGT"
    make
    make DESTDIR="$LFS" install
    clean_pkg "gzip-${GZIP_VER}"
}

# =============================================================================
# 6.12 — Make-4.4.1
# =============================================================================
build_make() {
    build_pkg "make-${MAKE_VER}.tar.gz" "make-${MAKE_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "make-${MAKE_VER}"
}

# =============================================================================
# 6.13 — Patch-2.8
# =============================================================================
build_patch() {
    build_pkg "patch-${PATCH_VER}.tar.xz" "patch-${PATCH_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "patch-${PATCH_VER}"
}

# =============================================================================
# 6.14 — Sed-4.9
# =============================================================================
build_sed() {
    build_pkg "sed-${SED_VER}.tar.xz" "sed-${SED_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(./build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "sed-${SED_VER}"
}

# =============================================================================
# 6.15 — Tar-1.35
# =============================================================================
build_tar() {
    build_pkg "tar-${TAR_VER}.tar.xz" "tar-${TAR_VER}"
    ./configure --prefix=/usr   \
                --host="$LFS_TGT" \
                --build="$(build-aux/config.guess)"
    make
    make DESTDIR="$LFS" install
    clean_pkg "tar-${TAR_VER}"
}

# =============================================================================
# 6.16 — Xz-5.8.2
# =============================================================================
build_xz() {
    build_pkg "xz-${XZ_VER}.tar.xz" "xz-${XZ_VER}"
    ./configure --prefix=/usr                   \
                --host="$LFS_TGT"               \
                --build="$(build-aux/config.guess)" \
                --disable-static                \
                --docdir="/usr/share/doc/xz-${XZ_VER}"
    make
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/liblzma.la"
    clean_pkg "xz-${XZ_VER}"
}

# =============================================================================
# 6.17 — Binutils-2.46.0 (Pass 2)
# =============================================================================
build_binutils_pass2() {
    build_pkg "binutils-${BINUTILS_VER}.tar.xz" "binutils-${BINUTILS_VER}"

    sed '6031s/$add_dir//' -i ltmain.sh

    mkdir -v build && cd build
    ../configure                        \
        --prefix=/usr                   \
        --build="$(../config.guess)"    \
        --host="$LFS_TGT"               \
        --disable-nls                   \
        --enable-shared                 \
        --enable-gprofng=no             \
        --disable-werror                \
        --enable-64-bit-bfd             \
        --enable-new-dtags              \
        --enable-default-hash-style=gnu
    make
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/lib"{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
    clean_pkg "binutils-${BINUTILS_VER}"
}

# =============================================================================
# 6.18 — GCC-15.2.0 (Pass 2)
# =============================================================================
build_gcc_pass2() {
    build_pkg "gcc-${GCC_VER}.tar.xz" "gcc-${GCC_VER}"

    tar -xf "$SRC/mpfr-${MPFR_VER}.tar.xz" && mv -v "mpfr-${MPFR_VER}" mpfr
    tar -xf "$SRC/gmp-${GMP_VER}.tar.xz"   && mv -v "gmp-${GMP_VER}"   gmp
    tar -xf "$SRC/mpc-${MPC_VER}.tar.gz"   && mv -v "mpc-${MPC_VER}"   mpc

    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    sed '/thread_header =/s/@.*@/gthr-posix.h/' \
        -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

    mkdir -v build && cd build
    ../configure                                    \
        --build="$(../config.guess)"                \
        --host="$LFS_TGT"                           \
        --target="$LFS_TGT"                         \
        --prefix=/usr                               \
        --with-build-sysroot="$LFS"                 \
        --enable-default-pie                        \
        --enable-default-ssp                        \
        --disable-nls                               \
        --disable-multilib                          \
        --disable-libatomic                         \
        --disable-libgomp                           \
        --disable-libquadmath                       \
        --disable-libsanitizer                      \
        --disable-libssp                            \
        --disable-libvtv                            \
        --enable-languages=c,c++                    \
        LDFLAGS_FOR_TARGET="-L$PWD/$LFS_TGT/libgcc"
    make
    make DESTDIR="$LFS" install
    ln -sv gcc "$LFS/usr/bin/cc"
    clean_pkg "gcc-${GCC_VER}"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 3 : Outils temporaires croisés (Chapitre 6) ==="

    build_m4
    build_ncurses
    build_bash
    build_coreutils
    build_diffutils
    build_file
    build_findutils
    build_gawk
    build_grep
    build_gzip
    build_make
    build_patch
    build_sed
    build_tar
    build_xz
    build_binutils_pass2
    build_gcc_pass2

    log_ok "=== Phase 3 terminée — Outils temporaires construits ==="
    log_info "Lancez maintenant en tant que ROOT : sudo bash scripts/04_chroot_prep.sh"
}

main "$@"
