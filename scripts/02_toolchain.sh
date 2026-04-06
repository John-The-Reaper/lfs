#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 2 : Compilation de la chaîne d'outils croisée
# À exécuter en tant qu'utilisateur LFS (su - lfs)
# Chapitre 5 du livre LFS
# =============================================================================
set -e
source "$(dirname "$0")/00_config.sh"

[[ "$(whoami)" != "lfs" ]] && log_error "Ce script doit être exécuté en tant que lfs."
check_lfs

SRC="$LFS/sources"
cd "$SRC"

# Helper : extraire + entrer dans le dossier source, puis nettoyer
build_pkg() {
    local tarball="$1"
    local dir="$2"
    log_info "Construction de $dir..."
    tar -xf "$tarball"
    cd "$dir"
}

clean_pkg() {
    local dir="$1"
    cd "$SRC"
    rm -rf "$dir"
    log_ok "$dir installé et nettoyé."
}

# =============================================================================
# 5.2 — Binutils-2.46.0 (Pass 1)
# Durée : ~1 SBU / Espace : 691 Mo
# =============================================================================
build_binutils_pass1() {
    build_pkg "binutils-${BINUTILS_VER}.tar.xz" "binutils-${BINUTILS_VER}"

    mkdir -v build && cd build
    ../configure                    \
        --prefix="$LFS/tools"       \
        --with-sysroot="$LFS"       \
        --target="$LFS_TGT"         \
        --disable-nls               \
        --enable-gprofng=no         \
        --disable-werror            \
        --enable-new-dtags          \
        --enable-default-hash-style=gnu
    make
    make install

    cd "$SRC"
    clean_pkg "binutils-${BINUTILS_VER}"
}

# =============================================================================
# 5.3 — GCC-15.2.0 (Pass 1)
# Durée : ~3.8 SBU / Espace : 5.4 Go
# =============================================================================
build_gcc_pass1() {
    build_pkg "gcc-${GCC_VER}.tar.xz" "gcc-${GCC_VER}"

    # Patch x86_64 : lib64 -> lib
    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    # Dépendances GMP, MPFR, MPC
    tar -xf "$SRC/mpfr-${MPFR_VER}.tar.xz" && mv -v "mpfr-${MPFR_VER}" mpfr
    tar -xf "$SRC/gmp-${GMP_VER}.tar.xz"   && mv -v "gmp-${GMP_VER}"   gmp
    tar -xf "$SRC/mpc-${MPC_VER}.tar.gz"   && mv -v "mpc-${MPC_VER}"   mpc

    mkdir -v build && cd build
    ../configure                        \
        --target="$LFS_TGT"             \
        --prefix="$LFS/tools"           \
        --with-glibc-version="${GLIBC_VER}" \
        --with-sysroot="$LFS"           \
        --with-newlib                   \
        --without-headers               \
        --enable-default-pie            \
        --enable-default-ssp            \
        --disable-nls                   \
        --disable-shared                \
        --disable-multilib              \
        --disable-threads               \
        --disable-libatomic             \
        --disable-libgomp               \
        --disable-libquadmath           \
        --disable-libssp                \
        --disable-libvtv                \
        --disable-libstdcxx             \
        --enable-languages=c,c++
    make
    make install

    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        "$(dirname "$($LFS_TGT-gcc -print-libgcc-file-name)")"/include/limits.h

    cd "$SRC"
    clean_pkg "gcc-${GCC_VER}"
}

# =============================================================================
# 5.4 — Linux-6.18.10 API Headers
# Durée : <0.1 SBU / Espace : 1.7 Go
# =============================================================================
build_linux_headers() {
    build_pkg "linux-${LINUX_VER}.tar.xz" "linux-${LINUX_VER}"

    make mrproper
    make headers
    find usr/include -type f ! -name '*.h' -delete
    cp -rv usr/include "$LFS/usr"

    cd "$SRC"
    clean_pkg "linux-${LINUX_VER}"
}

# =============================================================================
# 5.5 — Glibc-2.43
# Durée : ~1.4 SBU / Espace : 890 Mo
# =============================================================================
build_glibc() {
    # Liens symboliques LSB
    case $(uname -m) in
        i?86)
            ln -sfv ld-linux.so.2 "$LFS/lib/ld-lsb.so.3"
        ;;
        x86_64)
            ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
            ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3"
        ;;
    esac

    build_pkg "glibc-${GLIBC_VER}.tar.xz" "glibc-${GLIBC_VER}"

    patch -Np1 -i "$SRC/glibc-fhs-1.patch"

    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms

    ../configure                            \
        --prefix=/usr                       \
        --host="$LFS_TGT"                   \
        --build="$(../scripts/config.guess)" \
        --disable-nscd                      \
        libc_cv_slibdir=/usr/lib            \
        --enable-kernel=5.4
    make
    make DESTDIR="$LFS" install

    # Corriger le chargeur ldd
    sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"

    # Sanity check
    log_info "Vérification de la toolchain Glibc..."
    echo 'int main(){}' | "$LFS_TGT-gcc" -xc - -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib' | grep -q "ld-linux" \
        && log_ok "Toolchain OK : chargeur dynamique correct." \
        || log_warn "Vérifiez dummy.log — le chargeur dynamique peut être incorrect."
    rm -v a.out dummy.log

    cd "$SRC"
    clean_pkg "glibc-${GLIBC_VER}"
}

# =============================================================================
# 5.6 — Libstdc++ from GCC-15.2.0
# Durée : ~0.2 SBU / Espace : 1.3 Go
# =============================================================================
build_libstdcxx() {
    build_pkg "gcc-${GCC_VER}.tar.xz" "gcc-${GCC_VER}"

    mkdir -v build && cd build
    ../libstdc++-v3/configure               \
        --host="$LFS_TGT"                   \
        --build="$(../config.guess)"        \
        --prefix=/usr                       \
        --disable-multilib                  \
        --disable-nls                       \
        --disable-libstdcxx-pch             \
        --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/${GCC_VER}"
    make
    make DESTDIR="$LFS" install

    rm -v "$LFS/usr/lib/lib"{stdc++{,exp,fs},supc++}.la

    cd "$SRC"
    clean_pkg "gcc-${GCC_VER}"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 2 : Chaîne d'outils croisée (Chapitre 5) ==="
    log_warn "Assurez-vous que tous les tarballs sont dans $SRC avant de continuer."

    build_binutils_pass1
    build_gcc_pass1
    build_linux_headers
    build_glibc
    build_libstdcxx

    log_ok "=== Phase 2 terminée — Chaîne croisée construite dans \$LFS/tools ==="
    log_info "Lancez maintenant (toujours en tant que lfs) : bash scripts/03_temp_tools.sh"
}

main "$@"
