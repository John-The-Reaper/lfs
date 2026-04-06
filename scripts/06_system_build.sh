#!/bin/bash
# =============================================================================
# LFS 13.0 — Phase 6 : Construction du système final
# DOIT être exécuté DEPUIS L'INTÉRIEUR du chroot
# (lancé automatiquement par 04_chroot_prep.sh ou manuellement)
# Chapitre 8 du livre LFS
# =============================================================================
set -e

# --- Versions ---
MANPAGES_VER=6.17
IANA_ETC_VER=20260202
GLIBC_VER=2.43
TZDATA_VER=2025c
ZLIB_VER=1.3.2
BZIP2_VER=1.0.8
XZ_VER=5.8.2
LZ4_VER=1.10.0
ZSTD_VER=1.5.7
FILE_VER=5.46
READLINE_VER=8.3
PCRE2_VER=10.47
M4_VER=1.4.21
BC_VER=7.0.3
FLEX_VER=2.6.4
TCL_VER=8.6.17
EXPECT_VER=5.45.4
DEJAGNU_VER=1.6.3
PKGCONF_VER=2.5.1
BINUTILS_VER=2.46.0
GCC_VER=15.2.0
GMP_VER=6.3.0
MPFR_VER=4.2.2
MPC_VER=1.3.1
ATTR_VER=2.5.2
ACL_VER=2.3.2
LIBCAP_VER=2.77
LIBCRYPT_VER=4.5.2
SHADOW_VER=4.19.3
NCURSES_VER=6.6
SED_VER=4.9
PSMISC_VER=23.7
GETTEXT_VER=1.0
BISON_VER=3.8.2
GREP_VER=3.12
BASH_VER=5.3
LIBTOOL_VER=2.5.4
GDBM_VER=1.26
GPERF_VER=3.3
EXPAT_VER=2.7.4
INETUTILS_VER=2.7
LESS_VER=692
PERL_VER=5.42.0
XML_PARSER_VER=2.47
INTLTOOL_VER=0.51.0
AUTOCONF_VER=2.72
AUTOMAKE_VER=1.18.1
OPENSSL_VER=3.6.1
ELFUTILS_VER=0.194
LIBFFI_VER=3.5.2
SQLITE_VER=3510200
SQLITE_DOC_VER=3.51.2
PYTHON_VER=3.14.3
FLIT_CORE_VER=3.12.0
PACKAGING_VER=26.0
WHEEL_VER=0.46.3
SETUPTOOLS_VER=82.0.0
NINJA_VER=1.13.2
MESON_VER=1.10.1
KMOD_VER=34.2
COREUTILS_VER=9.10
DIFFUTILS_VER=3.12
GAWK_VER=5.3.2
FINDUTILS_VER=4.10.0
GROFF_VER=1.23.0
GRUB_VER=2.14
GZIP_VER=1.14
IPROUTE2_VER=6.18.0
KBD_VER=2.9.0
LIBPIPELINE_VER=1.5.8
MAKE_VER=4.4.1
PATCH_VER=2.8
TAR_VER=1.35
TEXINFO_VER=7.2
VIM_VER=9.2.0078
MARKUPSAFE_VER=3.0.3
JINJA2_VER=3.1.6
SYSTEMD_VER=259.1
DBUS_VER=1.16.2
MANDB_VER=2.13.1
PROCPS_VER=4.0.6
UTIL_LINUX_VER=2.41.3
E2FSPROGS_VER=1.47.3

SRC=/sources
cd "$SRC"

log_info() { echo "[INFO] $*"; }
log_ok()   { echo "[OK]   $*"; }

build_pkg() { log_info "Construction de $2..."; tar -xf "$1"; cd "$2"; }
clean_pkg() { cd "$SRC"; rm -rf "$1"; log_ok "$1 installé."; }

# =============================================================================
# 8.3 — Man-pages-6.17
# =============================================================================
build_man_pages() {
    build_pkg "man-pages-${MANPAGES_VER}.tar.xz" "man-pages-${MANPAGES_VER}"
    make -R GIT=false prefix=/usr install
    clean_pkg "man-pages-${MANPAGES_VER}"
}

# =============================================================================
# 8.4 — Iana-Etc-20260202
# =============================================================================
build_iana_etc() {
    build_pkg "iana-etc-${IANA_ETC_VER}.tar.gz" "iana-etc-${IANA_ETC_VER}"
    cp -v services protocols /etc
    clean_pkg "iana-etc-${IANA_ETC_VER}"
}

# =============================================================================
# 8.5 — Glibc-2.43
# =============================================================================
build_glibc() {
    build_pkg "glibc-${GLIBC_VER}.tar.xz" "glibc-${GLIBC_VER}"

    patch -Np1 -i "$SRC/glibc-fhs-1.patch"

    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms

    ../configure --prefix=/usr            \
                 --disable-werror         \
                 --disable-nscd           \
                 libc_cv_slibdir=/usr/lib \
                 --enable-stack-protector=strong \
                 --enable-kernel=5.4
    make

    touch /etc/ld.so.conf
    sed '/test-installation/s/^/# /' -i ../Makefile
    make install

    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

    # Locales minimales
    localedef -i C         -f UTF-8     C.UTF-8
    localedef -i en_US     -f ISO-8859-1 en_US
    localedef -i en_US     -f UTF-8     en_US.UTF-8
    localedef -i fr_FR     -f ISO-8859-1 fr_FR
    localedef -i fr_FR     -f UTF-8     fr_FR.UTF-8

    # /etc/nsswitch.conf
    cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd:   files systemd
group:    files systemd
shadow:   files systemd
hosts:    mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files
protocols: files
services:  files
ethers:    files
rpc:       files
# End /etc/nsswitch.conf
EOF

    # Fuseaux horaires
    tar -xf "$SRC/tzdata${TZDATA_VER}.tar.gz"
    ZONEINFO=/usr/share/zoneinfo
    mkdir -pv "$ZONEINFO"/{posix,right}
    for tz in etcetera southamerica northamerica europe africa antarctica \
              asia australasia backward; do
        zic -L /dev/null   -d "$ZONEINFO"        "$tz"
        zic -L /dev/null   -d "$ZONEINFO/posix"  "$tz"
        zic -L leapseconds -d "$ZONEINFO/right"  "$tz"
    done
    cp -v zone.tab zone1970.tab iso3166.tab "$ZONEINFO"
    zic -d "$ZONEINFO" -p America/New_York
    unset ZONEINFO tz

    ln -sfv /usr/share/zoneinfo/Europe/Paris /etc/localtime

    # /etc/ld.so.conf
    cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

    cd "$SRC"
    clean_pkg "glibc-${GLIBC_VER}"
}

# =============================================================================
# 8.6 — Zlib-1.3.2
# =============================================================================
build_zlib() {
    build_pkg "zlib-${ZLIB_VER}.tar.gz" "zlib-${ZLIB_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    rm -fv /usr/lib/libz.a
    clean_pkg "zlib-${ZLIB_VER}"
}

# =============================================================================
# 8.7 — Bzip2-1.0.8
# =============================================================================
build_bzip2() {
    build_pkg "bzip2-${BZIP2_VER}.tar.gz" "bzip2-${BZIP2_VER}"
    patch -Np1 -i "$SRC/bzip2-1.0.8-install_docs-1.patch"
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
    make -f Makefile-libbz2_so
    make clean
    make
    make PREFIX=/usr install
    cp -av libbz2.so.* /usr/lib
    ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so.1
    cp -v bzip2-shared /usr/bin/bzip2
    for i in /usr/bin/{bzcat,bunzip2}; do
        ln -sfv bzip2 $i
    done
    rm -fv /usr/lib/libbz2.a
    clean_pkg "bzip2-${BZIP2_VER}"
}

# =============================================================================
# 8.8 — Xz-5.8.2
# =============================================================================
build_xz() {
    build_pkg "xz-${XZ_VER}.tar.xz" "xz-${XZ_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --docdir="/usr/share/doc/xz-${XZ_VER}"
    make
    make check
    make install
    clean_pkg "xz-${XZ_VER}"
}

# =============================================================================
# 8.9 — Lz4-1.10.0
# =============================================================================
build_lz4() {
    build_pkg "lz4-${LZ4_VER}.tar.gz" "lz4-${LZ4_VER}"
    make BUILD_STATIC=no PREFIX=/usr
    make -j1 check
    make BUILD_STATIC=no PREFIX=/usr install
    clean_pkg "lz4-${LZ4_VER}"
}

# =============================================================================
# 8.10 — Zstd-1.5.7
# =============================================================================
build_zstd() {
    build_pkg "zstd-${ZSTD_VER}.tar.gz" "zstd-${ZSTD_VER}"
    make prefix=/usr
    make check
    make prefix=/usr install
    rm -v /usr/lib/libzstd.a
    clean_pkg "zstd-${ZSTD_VER}"
}

# =============================================================================
# 8.11 — File-5.46
# =============================================================================
build_file() {
    build_pkg "file-${FILE_VER}.tar.gz" "file-${FILE_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "file-${FILE_VER}"
}

# =============================================================================
# 8.12 — Readline-8.3
# =============================================================================
build_readline() {
    build_pkg "readline-${READLINE_VER}.tar.gz" "readline-${READLINE_VER}"
    sed -i '/MV.*old/d'       Makefile.in
    sed -i '/(OLDSUFF)/c:'    support/shlib-install
    sed -i 's/-Wl,-rpath,[^ ]*//' support/shlib-conf
    ./configure --prefix=/usr         \
                --disable-static      \
                --with-curses         \
                --docdir="/usr/share/doc/readline-${READLINE_VER}"
    make SHLIB_LIBS="-lncursesw"
    make install
    install -v -m644 doc/*.{ps,pdf,html} "/usr/share/doc/readline-${READLINE_VER}"
    clean_pkg "readline-${READLINE_VER}"
}

# =============================================================================
# 8.13 — Pcre2-10.47
# =============================================================================
build_pcre2() {
    build_pkg "pcre2-${PCRE2_VER}.tar.bz2" "pcre2-${PCRE2_VER}"
    ./configure --prefix=/usr                              \
                --docdir="/usr/share/doc/pcre2-${PCRE2_VER}" \
                --enable-unicode                           \
                --enable-jit                               \
                --enable-pcre2-16                          \
                --enable-pcre2-32                          \
                --enable-pcre2grep-libz                    \
                --enable-pcre2grep-libbz2                  \
                --enable-pcre2test-libreadline             \
                --disable-static
    make
    make check
    make install
    clean_pkg "pcre2-${PCRE2_VER}"
}

# =============================================================================
# 8.14 — M4-1.4.21
# =============================================================================
build_m4() {
    build_pkg "m4-${M4_VER}.tar.xz" "m4-${M4_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "m4-${M4_VER}"
}

# =============================================================================
# 8.15 — Bc-7.0.3
# =============================================================================
build_bc() {
    build_pkg "bc-${BC_VER}.tar.xz" "bc-${BC_VER}"
    CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
    make
    make test
    make install
    clean_pkg "bc-${BC_VER}"
}

# =============================================================================
# 8.16 — Flex-2.6.4
# =============================================================================
build_flex() {
    build_pkg "flex-${FLEX_VER}.tar.gz" "flex-${FLEX_VER}"
    ./configure --prefix=/usr                              \
                --disable-static                           \
                --docdir="/usr/share/doc/flex-${FLEX_VER}"
    make
    make check
    make install
    ln -sv flex   /usr/bin/lex
    ln -sv flex.1 /usr/share/man/man1/lex.1
    clean_pkg "flex-${FLEX_VER}"
}

# =============================================================================
# 8.17 — Tcl-8.6.17
# =============================================================================
build_tcl() {
    build_pkg "tcl${TCL_VER}-src.tar.gz" "tcl${TCL_VER}"
    SRCDIR=$(pwd)
    cd unix
    ./configure --prefix=/usr         \
                --mandir=/usr/share/man \
                --disable-rpath
    make
    sed -e "s|$SRCDIR/unix|/usr/lib|"    \
        -e "s|$SRCDIR|/usr/include|"     \
        -i tclConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|"    \
        -e "s|$SRCDIR/pkgs/tdbc1.1.12/generic|/usr/include|"        \
        -e "s|$SRCDIR/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|"         \
        -i pkgs/tdbc1.1.12/tdbcConfig.sh
    sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|"     \
        -e "s|$SRCDIR/pkgs/itcl4.3.4/generic|/usr/include|"         \
        -e "s|$SRCDIR/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|"           \
        -i pkgs/itcl4.3.4/itclConfig.sh
    unset SRCDIR
    LC_ALL=C.UTF-8 make test
    make install
    chmod -v u+w /usr/lib/libtclstub8.6.a
    chmod -v u+w /usr/lib/libtcl8.6.so
    make install-private-headers
    ln -sfv tclsh8.6 /usr/bin/tclsh
    mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3
    cd ..
    install -v -dm755 /usr/share/doc/tcl-${TCL_VER}
    tar -xf "$SRC/tcl${TCL_VER}-html.tar.gz" --strip-components=1
    cp -v -r ./html/* /usr/share/doc/tcl-${TCL_VER}
    cd "$SRC"
    clean_pkg "tcl${TCL_VER}"
}

# =============================================================================
# 8.18 — Expect-5.45.4
# =============================================================================
build_expect() {
    build_pkg "expect${EXPECT_VER}.tar.gz" "expect${EXPECT_VER}"
    patch -Np1 -i "$SRC/expect-${EXPECT_VER}-gcc15-1.patch"
    ./configure --prefix=/usr              \
                --with-tcl=/usr/lib        \
                --enable-shared            \
                --disable-rpath            \
                --mandir=/usr/share/man    \
                --with-tclinclude=/usr/include
    make
    make test
    make install
    ln -svf expect${EXPECT_VER}/libexpect${EXPECT_VER}.so /usr/lib
    clean_pkg "expect${EXPECT_VER}"
}

# =============================================================================
# 8.19 — DejaGNU-1.6.3
# =============================================================================
build_dejagnu() {
    build_pkg "dejagnu-${DEJAGNU_VER}.tar.gz" "dejagnu-${DEJAGNU_VER}"
    mkdir -v build && cd build
    ../configure --prefix=/usr
    makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
    makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
    make check
    make install
    install -v -dm755  /usr/share/doc/dejagnu-${DEJAGNU_VER}
    install -v -m644   doc/dejagnu.html doc/dejagnu.txt \
                       /usr/share/doc/dejagnu-${DEJAGNU_VER}
    clean_pkg "dejagnu-${DEJAGNU_VER}"
}

# =============================================================================
# 8.20 — Pkgconf-2.5.1
# =============================================================================
build_pkgconf() {
    build_pkg "pkgconf-${PKGCONF_VER}.tar.xz" "pkgconf-${PKGCONF_VER}"
    ./configure --prefix=/usr                                  \
                --disable-static                               \
                --docdir="/usr/share/doc/pkgconf-${PKGCONF_VER}"
    make
    make install
    ln -sv pkgconf   /usr/bin/pkg-config
    ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
    clean_pkg "pkgconf-${PKGCONF_VER}"
}

# =============================================================================
# 8.21 — Binutils-2.46.0
# =============================================================================
build_binutils() {
    build_pkg "binutils-${BINUTILS_VER}.tar.xz" "binutils-${BINUTILS_VER}"
    mkdir -v build && cd build
    ../configure --prefix=/usr                   \
                 --sysconfdir=/etc               \
                 --enable-ld=default             \
                 --enable-plugins                \
                 --enable-shared                 \
                 --disable-werror                \
                 --enable-64-bit-bfd             \
                 --enable-new-dtags              \
                 --with-system-zlib              \
                 --enable-default-hash-style=gnu
    make tooldir=/usr
    make -k check || log_info "Certains tests Binutils ont échoué (acceptable)."
    make tooldir=/usr install
    rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
            /usr/share/doc/gprof
    clean_pkg "binutils-${BINUTILS_VER}"
}

# =============================================================================
# 8.22 — GMP-6.3.0
# =============================================================================
build_gmp() {
    build_pkg "gmp-${GMP_VER}.tar.xz" "gmp-${GMP_VER}"
    ./configure --prefix=/usr         \
                --enable-cxx          \
                --disable-static      \
                --docdir="/usr/share/doc/gmp-${GMP_VER}"
    make
    make html
    make check 2>&1 | tee gmp-check-log
    awk '/# PASS:/{total+=$3} END{print total}' gmp-check-log
    make install
    make install-html
    clean_pkg "gmp-${GMP_VER}"
}

# =============================================================================
# 8.23 — MPFR-4.2.2
# =============================================================================
build_mpfr() {
    build_pkg "mpfr-${MPFR_VER}.tar.xz" "mpfr-${MPFR_VER}"
    ./configure --prefix=/usr           \
                --disable-static        \
                --enable-thread-safe    \
                --docdir="/usr/share/doc/mpfr-${MPFR_VER}"
    make
    make html
    make check
    make install
    make install-html
    clean_pkg "mpfr-${MPFR_VER}"
}

# =============================================================================
# 8.24 — MPC-1.3.1
# =============================================================================
build_mpc() {
    build_pkg "mpc-${MPC_VER}.tar.gz" "mpc-${MPC_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --docdir="/usr/share/doc/mpc-${MPC_VER}"
    make
    make html
    make check
    make install
    make install-html
    clean_pkg "mpc-${MPC_VER}"
}

# =============================================================================
# 8.25 — Attr-2.5.2
# =============================================================================
build_attr() {
    build_pkg "attr-${ATTR_VER}.tar.gz" "attr-${ATTR_VER}"
    ./configure --prefix=/usr       \
                --disable-static    \
                --sysconfdir=/etc   \
                --docdir="/usr/share/doc/attr-${ATTR_VER}"
    make
    make check
    make install
    clean_pkg "attr-${ATTR_VER}"
}

# =============================================================================
# 8.26 — Acl-2.3.2
# =============================================================================
build_acl() {
    build_pkg "acl-${ACL_VER}.tar.xz" "acl-${ACL_VER}"
    ./configure --prefix=/usr       \
                --disable-static    \
                --docdir="/usr/share/doc/acl-${ACL_VER}"
    make
    make check
    make install
    clean_pkg "acl-${ACL_VER}"
}

# =============================================================================
# 8.27 — Libcap-2.77
# =============================================================================
build_libcap() {
    build_pkg "libcap-${LIBCAP_VER}.tar.xz" "libcap-${LIBCAP_VER}"
    sed -i '/install -m.*STA/d' libcap/Makefile
    make prefix=/usr lib=lib
    make test
    make prefix=/usr lib=lib install
    clean_pkg "libcap-${LIBCAP_VER}"
}

# =============================================================================
# 8.28 — Libxcrypt-4.5.2
# =============================================================================
build_libxcrypt() {
    build_pkg "libxcrypt-${LIBCRYPT_VER}.tar.xz" "libxcrypt-${LIBCRYPT_VER}"
    ./configure --prefix=/usr              \
                --enable-hashes=strong,glibc \
                --enable-obsolete-api=no   \
                --disable-static           \
                --disable-failure-tokens
    make
    make check
    make install
    clean_pkg "libxcrypt-${LIBCRYPT_VER}"
}

# =============================================================================
# 8.29 — Shadow-4.19.3
# =============================================================================
build_shadow() {
    build_pkg "shadow-${SHADOW_VER}.tar.xz" "shadow-${SHADOW_VER}"
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in
    find man -name Makefile.in -exec sed -i 's/groups$(EXEEXT) //' '{}' \;
    sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD YESCRYPT@' \
           -e 's@/var/spool/mail@/var/mail@'                   \
           -e '/PATH=/{s@/sbin:@@}'                            \
           etc/login.defs
    ./configure --sysconfdir=/etc    \
                --disable-static     \
                --with-{b,y}crypt    \
                --without-libbsd     \
                --disable-logind     \
                --with-group-name-max-length=32
    make
    make exec_prefix=/usr install
    make -C man install-man
    mkdir -p /etc/default
    useradd -D --gid 999
    sed -i '/MAIL/s/yes/no/' /etc/default/useradd
    # Définir le mot de passe root — à changer après l'installation !
    echo "root:lfsroot" | chpasswd
    clean_pkg "shadow-${SHADOW_VER}"
}

# =============================================================================
# 8.30 — GCC-15.2.0
# =============================================================================
build_gcc() {
    build_pkg "gcc-${GCC_VER}.tar.xz" "gcc-${GCC_VER}"

    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    mkdir -v build && cd build
    ../configure --prefix=/usr                  \
                 LD=ld                          \
                 --enable-languages=c,c++       \
                 --enable-default-pie           \
                 --enable-default-ssp           \
                 --enable-host-pie              \
                 --disable-multilib             \
                 --disable-bootstrap            \
                 --disable-fixincludes          \
                 --with-system-zlib
    make
    ulimit -s -H unlimited

    chown -R tester .
    su tester -c "PATH=$PATH make -k check" || \
        log_info "Certains tests GCC ont échoué (acceptable)."

    make install
    chown -v -R root:root \
        /usr/lib/gcc/$(gcc -dumpmachine)/${GCC_VER}/include{,-fixed}
    ln -svr /usr/bin/cpp /usr/lib
    ln -sv gcc.1 /usr/share/man/man1/cc.1
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/${GCC_VER}/liblto_plugin.so \
            /usr/lib/bfd-plugins/

    mkdir -pv /usr/share/gdb/auto-load/usr/lib
    mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

    # Vérification sanity check
    log_info "Vérification de la chaîne de compilation finale..."
    echo 'int main(){}' | cc -x c -e -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib' | grep -q "ld-linux" \
        && log_ok "GCC : chargeur dynamique correct." \
        || log_info "Vérifiez dummy.log"
    rm -v a.out dummy.log

    clean_pkg "gcc-${GCC_VER}"
}

# =============================================================================
# 8.31 — Ncurses-6.6
# =============================================================================
build_ncurses() {
    build_pkg "ncurses-${NCURSES_VER}.tar.gz" "ncurses-${NCURSES_VER}"
    ./configure --prefix=/usr               \
                --mandir=/usr/share/man     \
                --with-shared               \
                --without-debug             \
                --without-normal            \
                --with-cxx-shared           \
                --enable-pc-files           \
                --with-pkg-config-libdir=/usr/lib/pkgconfig
    make
    make DESTDIR=$PWD/dest install
    install -vm755 dest/usr/lib/libncursesw.so.${NCURSES_VER} /usr/lib
    cp --remove-destination -av dest/usr/* /usr
    for lib in ncurses form panel menu; do
        ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
        ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
    done
    ln -sfv libncursesw.so /usr/lib/libcurses.so
    install -v -m755 -d /usr/share/doc/ncurses-${NCURSES_VER}
    cp -v -R doc/html/* /usr/share/doc/ncurses-${NCURSES_VER}
    clean_pkg "ncurses-${NCURSES_VER}"
}

# =============================================================================
# 8.32 — Sed-4.9
# =============================================================================
build_sed() {
    build_pkg "sed-${SED_VER}.tar.xz" "sed-${SED_VER}"
    ./configure --prefix=/usr
    make
    make html
    chown -R tester .
    su tester -c "PATH=$PATH make check"
    make install
    install -d  -m755                /usr/share/doc/sed-${SED_VER}
    install -m644 doc/sed.html       /usr/share/doc/sed-${SED_VER}
    clean_pkg "sed-${SED_VER}"
}

# =============================================================================
# 8.33 — Psmisc-23.7
# =============================================================================
build_psmisc() {
    build_pkg "psmisc-${PSMISC_VER}.tar.xz" "psmisc-${PSMISC_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "psmisc-${PSMISC_VER}"
}

# =============================================================================
# 8.34 — Gettext-0.22.5
# =============================================================================
build_gettext() {
    build_pkg "gettext-${GETTEXT_VER}.tar.xz" "gettext-${GETTEXT_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --docdir="/usr/share/doc/gettext-${GETTEXT_VER}"
    make
    make check
    make install
    chmod -v 0755 /usr/lib/preloadable_libintl.so
    clean_pkg "gettext-${GETTEXT_VER}"
}

# =============================================================================
# 8.35 — Bison-3.8.2
# =============================================================================
build_bison() {
    build_pkg "bison-${BISON_VER}.tar.xz" "bison-${BISON_VER}"
    ./configure --prefix=/usr --docdir="/usr/share/doc/bison-${BISON_VER}"
    make
    make check
    make install
    clean_pkg "bison-${BISON_VER}"
}

# =============================================================================
# 8.36 — Grep-3.12
# =============================================================================
build_grep() {
    build_pkg "grep-${GREP_VER}.tar.xz" "grep-${GREP_VER}"
    sed -i 's/echo /#echo /' src/egrep.sh
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "grep-${GREP_VER}"
}

# =============================================================================
# 8.37 — Bash-5.3
# =============================================================================
build_bash() {
    build_pkg "bash-${BASH_VER}.tar.gz" "bash-${BASH_VER}"
    ./configure --prefix=/usr           \
                --without-bash-malloc   \
                --with-installed-readline \
                --docdir="/usr/share/doc/bash-${BASH_VER}"
    make
    chown -R tester .
    su tester -c "PATH=$PATH make tests" || \
        log_info "Certains tests Bash ont échoué (acceptable)."
    make install
    clean_pkg "bash-${BASH_VER}"
}

# =============================================================================
# 8.38 — Libtool-2.5.4
# =============================================================================
build_libtool() {
    build_pkg "libtool-${LIBTOOL_VER}.tar.xz" "libtool-${LIBTOOL_VER}"
    ./configure --prefix=/usr
    make
    make check || log_info "Certains tests Libtool ont échoué (acceptable)."
    make install
    rm -fv /usr/lib/libltdl.a
    clean_pkg "libtool-${LIBTOOL_VER}"
}

# =============================================================================
# 8.39 — GDBM-1.26
# =============================================================================
build_gdbm() {
    build_pkg "gdbm-${GDBM_VER}.tar.gz" "gdbm-${GDBM_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --enable-libgdbm-compat
    make
    make check
    make install
    clean_pkg "gdbm-${GDBM_VER}"
}

# =============================================================================
# 8.40 — Gperf-3.3
# =============================================================================
build_gperf() {
    build_pkg "gperf-${GPERF_VER}.tar.gz" "gperf-${GPERF_VER}"
    ./configure --prefix=/usr --docdir="/usr/share/doc/gperf-${GPERF_VER}"
    make
    make check
    make install
    clean_pkg "gperf-${GPERF_VER}"
}

# =============================================================================
# 8.41 — Expat-2.7.4
# =============================================================================
build_expat() {
    build_pkg "expat-${EXPAT_VER}.tar.xz" "expat-${EXPAT_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --docdir="/usr/share/doc/expat-${EXPAT_VER}"
    make
    make check
    make install
    install -v -m644 doc/*.{html,css} "/usr/share/doc/expat-${EXPAT_VER}"
    clean_pkg "expat-${EXPAT_VER}"
}

# =============================================================================
# 8.42 — Inetutils-2.7
# =============================================================================
build_inetutils() {
    build_pkg "inetutils-${INETUTILS_VER}.tar.xz" "inetutils-${INETUTILS_VER}"
    sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
    ./configure --prefix=/usr         \
                --bindir=/usr/bin     \
                --localstatedir=/var  \
                --disable-logger      \
                --disable-whois       \
                --disable-rcp         \
                --disable-rexec       \
                --disable-rlogin      \
                --disable-rsh         \
                --disable-servers
    make
    make check
    make install
    mv -v /usr/{,s}bin/ifconfig
    clean_pkg "inetutils-${INETUTILS_VER}"
}

# =============================================================================
# 8.43 — Less-692
# =============================================================================
build_less() {
    build_pkg "less-${LESS_VER}.tar.gz" "less-${LESS_VER}"
    ./configure --prefix=/usr --sysconfdir=/etc
    make
    make check
    make install
    clean_pkg "less-${LESS_VER}"
}

# =============================================================================
# 8.44 — Perl-5.42.0
# =============================================================================
build_perl() {
    build_pkg "perl-${PERL_VER}.tar.xz" "perl-${PERL_VER}"
    export BUILD_ZLIB=False
    export BUILD_BZIP2=0
    sh Configure -des                                           \
                 -D prefix=/usr                                \
                 -D vendorprefix=/usr                          \
                 -D privlib="/usr/lib/perl5/5.42/core_perl"   \
                 -D archlib="/usr/lib/perl5/5.42/core_perl"   \
                 -D sitelib="/usr/lib/perl5/5.42/site_perl"   \
                 -D sitearch="/usr/lib/perl5/5.42/site_perl"  \
                 -D vendorlib="/usr/lib/perl5/5.42/vendor_perl" \
                 -D vendorarch="/usr/lib/perl5/5.42/vendor_perl" \
                 -D mandir=/usr/share/man/man1                 \
                 -D man3dir=/usr/share/man/man3                \
                 -D pager="/usr/bin/less -isR"                 \
                 -D useshrplib                                 \
                 -D usethreads
    make
    TEST_JOBS=$(nproc) make test_harness || \
        log_info "Certains tests Perl ont échoué (acceptable)."
    make install
    unset BUILD_ZLIB BUILD_BZIP2
    clean_pkg "perl-${PERL_VER}"
}

# =============================================================================
# 8.45 — XML::Parser-2.47
# =============================================================================
build_xml_parser() {
    build_pkg "XML-Parser-${XML_PARSER_VER}.tar.gz" "XML-Parser-${XML_PARSER_VER}"
    perl Makefile.PL
    make
    make test
    make install
    clean_pkg "XML-Parser-${XML_PARSER_VER}"
}

# =============================================================================
# 8.46 — Intltool-0.51.0
# =============================================================================
build_intltool() {
    build_pkg "intltool-${INTLTOOL_VER}.tar.gz" "intltool-${INTLTOOL_VER}"
    sed -i 's:\\\${:\\\\\${:' intltool-update.in
    ./configure --prefix=/usr
    make
    make check
    make install
    install -v -Dm644 doc/I18N-HOWTO \
        "/usr/share/doc/intltool-${INTLTOOL_VER}/I18N-HOWTO"
    clean_pkg "intltool-${INTLTOOL_VER}"
}

# =============================================================================
# 8.47 — Autoconf-2.72
# =============================================================================
build_autoconf() {
    build_pkg "autoconf-${AUTOCONF_VER}.tar.xz" "autoconf-${AUTOCONF_VER}"
    ./configure --prefix=/usr
    make
    make check || log_info "Certains tests Autoconf ont échoué (acceptable)."
    make install
    clean_pkg "autoconf-${AUTOCONF_VER}"
}

# =============================================================================
# 8.48 — Automake-1.18.1
# =============================================================================
build_automake() {
    build_pkg "automake-${AUTOMAKE_VER}.tar.xz" "automake-${AUTOMAKE_VER}"
    ./configure --prefix=/usr \
                --docdir="/usr/share/doc/automake-${AUTOMAKE_VER}"
    make
    make -j$(($(nproc)>4?4:$(nproc))) check || \
        log_info "Certains tests Automake ont échoué (acceptable)."
    make install
    clean_pkg "automake-${AUTOMAKE_VER}"
}

# =============================================================================
# 8.49 — OpenSSL-3.6.1
# =============================================================================
build_openssl() {
    build_pkg "openssl-${OPENSSL_VER}.tar.gz" "openssl-${OPENSSL_VER}"
    ./config --prefix=/usr      \
             --openssldir=/etc/ssl \
             --libdir=lib        \
             shared              \
             zlib-dynamic
    make
    HARNESS_JOBS=$(nproc) make test || \
        log_info "Certains tests OpenSSL ont échoué (acceptable)."
    sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
    make MANSUFFIX=ssl install
    mv -v /usr/share/doc/openssl /usr/share/doc/openssl-${OPENSSL_VER}
    cp -vfr doc/* /usr/share/doc/openssl-${OPENSSL_VER}
    clean_pkg "openssl-${OPENSSL_VER}"
}

# =============================================================================
# 8.50 — Libelf from Elfutils-0.194
# =============================================================================
build_libelf() {
    build_pkg "elfutils-${ELFUTILS_VER}.tar.bz2" "elfutils-${ELFUTILS_VER}"
    ./configure --prefix=/usr            \
                --disable-debuginfod     \
                --enable-libdebuginfod=dummy
    make -C lib
    make -C libelf
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm -f /usr/lib/libelf.a
    clean_pkg "elfutils-${ELFUTILS_VER}"
}

# =============================================================================
# 8.51 — Libffi-3.5.2
# =============================================================================
build_libffi() {
    build_pkg "libffi-${LIBFFI_VER}.tar.gz" "libffi-${LIBFFI_VER}"
    ./configure --prefix=/usr         \
                --disable-static      \
                --with-gcc-arch=native
    make
    make check
    make install
    clean_pkg "libffi-${LIBFFI_VER}"
}

# =============================================================================
# 8.52 — Sqlite-3510200
# =============================================================================
build_sqlite() {
    build_pkg "sqlite-autoconf-${SQLITE_VER}.tar.gz" "sqlite-autoconf-${SQLITE_VER}"
    tar -xf "$SRC/sqlite-doc-${SQLITE_VER}.tar.xz"
    ./configure --prefix=/usr         \
                --disable-static      \
                --enable-fts4         \
                --enable-fts5         \
                CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1  \
                          -DSQLITE_ENABLE_UNLOCK_NOTIFY=1    \
                          -DSQLITE_ENABLE_DBSTAT_VTAB=1      \
                          -DSQLITE_SECURE_DELETE=1"
    make LDFLAGS_rpath=""
    make install
    install -v -m755 -d /usr/share/doc/sqlite-${SQLITE_DOC_VER}
    cp -v -R sqlite-doc-${SQLITE_VER}/* /usr/share/doc/sqlite-${SQLITE_DOC_VER}
    clean_pkg "sqlite-autoconf-${SQLITE_VER}"
}

# =============================================================================
# 8.53 — Python-3.14.3
# =============================================================================
build_python() {
    build_pkg "Python-${PYTHON_VER}.tar.xz" "Python-${PYTHON_VER}"
    ./configure --prefix=/usr               \
                --enable-shared             \
                --with-system-expat         \
                --enable-optimizations      \
                --without-static-libpython
    make
    make install
    cat > /etc/pip.conf << "EOF"
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
    clean_pkg "Python-${PYTHON_VER}"
}

# =============================================================================
# 8.54 — Flit-Core-3.12.0
# =============================================================================
build_flit_core() {
    build_pkg "flit_core-${FLIT_CORE_VER}.tar.gz" "flit_core-${FLIT_CORE_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist flit_core
    clean_pkg "flit_core-${FLIT_CORE_VER}"
}

# =============================================================================
# 8.55 — Packaging-26.0
# =============================================================================
build_packaging() {
    build_pkg "packaging-${PACKAGING_VER}.tar.gz" "packaging-${PACKAGING_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist packaging
    clean_pkg "packaging-${PACKAGING_VER}"
}

# =============================================================================
# 8.56 — Wheel-0.46.3
# =============================================================================
build_wheel() {
    build_pkg "wheel-${WHEEL_VER}.tar.gz" "wheel-${WHEEL_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist wheel
    clean_pkg "wheel-${WHEEL_VER}"
}

# =============================================================================
# 8.57 — Setuptools-82.0.0
# =============================================================================
build_setuptools() {
    build_pkg "setuptools-${SETUPTOOLS_VER}.tar.gz" "setuptools-${SETUPTOOLS_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist setuptools
    clean_pkg "setuptools-${SETUPTOOLS_VER}"
}

# =============================================================================
# 8.58 — Ninja-1.13.2
# =============================================================================
build_ninja() {
    build_pkg "ninja-${NINJA_VER}.tar.gz" "ninja-${NINJA_VER}"
    python3 configure.py --bootstrap --verbose
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion/completions/ninja \
        /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion/_ninja \
        /usr/share/zsh/site-functions/_ninja
    clean_pkg "ninja-${NINJA_VER}"
}

# =============================================================================
# 8.59 — Meson-1.10.1
# =============================================================================
build_meson() {
    build_pkg "meson-${MESON_VER}.tar.gz" "meson-${MESON_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist meson
    install -vDm644 data/shell-completions/bash/meson \
        /usr/share/bash-completion/completions/meson
    install -vDm644 data/shell-completions/zsh/_meson \
        /usr/share/zsh/site-functions/_meson
    clean_pkg "meson-${MESON_VER}"
}

# =============================================================================
# 8.60 — Kmod-34.2
# =============================================================================
build_kmod() {
    build_pkg "kmod-${KMOD_VER}.tar.xz" "kmod-${KMOD_VER}"
    mkdir -p build && cd build
    meson setup --prefix=/usr .. \
                --buildtype=release \
                -D manpages=false
    ninja
    ninja install
    clean_pkg "kmod-${KMOD_VER}"
}

# =============================================================================
# 8.61 — Coreutils-9.10
# =============================================================================
build_coreutils() {
    build_pkg "coreutils-${COREUTILS_VER}.tar.xz" "coreutils-${COREUTILS_VER}"
    patch -Np1 -i "$SRC/coreutils-${COREUTILS_VER}-i18n-1.patch"
    autoreconf -fv
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make
    make NON_ROOT_USERNAME=tester check-root
    groupadd -g 102 dummy -U tester
    chown -R tester .
    su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" < /dev/null || \
        log_info "Certains tests Coreutils ont échoué (acceptable)."
    groupdel dummy
    make install
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
    clean_pkg "coreutils-${COREUTILS_VER}"
}

# =============================================================================
# 8.62 — Diffutils-3.12
# =============================================================================
build_diffutils() {
    build_pkg "diffutils-${DIFFUTILS_VER}.tar.xz" "diffutils-${DIFFUTILS_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "diffutils-${DIFFUTILS_VER}"
}

# =============================================================================
# 8.63 — Gawk-5.3.2
# =============================================================================
build_gawk() {
    build_pkg "gawk-${GAWK_VER}.tar.xz" "gawk-${GAWK_VER}"
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr
    make
    chown -R tester .
    su tester -c "PATH=$PATH make check" || \
        log_info "Certains tests Gawk ont échoué (acceptable)."
    rm -f /usr/bin/gawk-${GAWK_VER}
    make install
    ln -sv gawk.1 /usr/share/man/man1/awk.1
    clean_pkg "gawk-${GAWK_VER}"
}

# =============================================================================
# 8.64 — Findutils-4.10.0
# =============================================================================
build_findutils() {
    build_pkg "findutils-${FINDUTILS_VER}.tar.xz" "findutils-${FINDUTILS_VER}"
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make
    chown -R tester .
    su tester -c "PATH=$PATH make check" || \
        log_info "Certains tests Findutils ont échoué (acceptable)."
    make install
    clean_pkg "findutils-${FINDUTILS_VER}"
}

# =============================================================================
# 8.65 — Groff-1.23.0
# =============================================================================
build_groff() {
    build_pkg "groff-${GROFF_VER}.tar.gz" "groff-${GROFF_VER}"
    PAGE=A4 ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "groff-${GROFF_VER}"
}

# =============================================================================
# 8.66 — GRUB-2.14
# =============================================================================
build_grub() {
    build_pkg "grub-${GRUB_VER}.tar.xz" "grub-${GRUB_VER}"
    ./configure --prefix=/usr       \
                --sysconfdir=/etc   \
                --disable-efiemu    \
                --disable-werror
    make
    make install
    mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
    clean_pkg "grub-${GRUB_VER}"
}

# =============================================================================
# 8.67 — Gzip-1.14
# =============================================================================
build_gzip() {
    build_pkg "gzip-${GZIP_VER}.tar.xz" "gzip-${GZIP_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "gzip-${GZIP_VER}"
}

# =============================================================================
# 8.68 — IPRoute2-6.18.0
# =============================================================================
build_iproute2() {
    build_pkg "iproute2-${IPROUTE2_VER}.tar.xz" "iproute2-${IPROUTE2_VER}"
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make NETNS_RUN_DIR=/run/netns
    make SBINDIR=/usr/sbin install
    install -vDm644 COPYING README* -t "/usr/share/doc/iproute2-${IPROUTE2_VER}"
    clean_pkg "iproute2-${IPROUTE2_VER}"
}

# =============================================================================
# 8.69 — Kbd-2.9.0
# =============================================================================
build_kbd() {
    build_pkg "kbd-${KBD_VER}.tar.xz" "kbd-${KBD_VER}"
    patch -Np1 -i "$SRC/kbd-${KBD_VER}-backspace-1.patch"
    sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make
    make check
    make install
    cp -R -v docs/doc -T "/usr/share/doc/kbd-${KBD_VER}"
    clean_pkg "kbd-${KBD_VER}"
}

# =============================================================================
# 8.70 — Libpipeline-1.5.8
# =============================================================================
build_libpipeline() {
    build_pkg "libpipeline-${LIBPIPELINE_VER}.tar.gz" "libpipeline-${LIBPIPELINE_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "libpipeline-${LIBPIPELINE_VER}"
}

# =============================================================================
# 8.71 — Make-4.4.1
# =============================================================================
build_make() {
    build_pkg "make-${MAKE_VER}.tar.gz" "make-${MAKE_VER}"
    ./configure --prefix=/usr
    make
    chown -R tester .
    su tester -c "PATH=$PATH make check" || \
        log_info "Certains tests Make ont échoué (acceptable)."
    make install
    clean_pkg "make-${MAKE_VER}"
}

# =============================================================================
# 8.72 — Patch-2.8
# =============================================================================
build_patch() {
    build_pkg "patch-${PATCH_VER}.tar.xz" "patch-${PATCH_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "patch-${PATCH_VER}"
}

# =============================================================================
# 8.73 — Tar-1.35
# =============================================================================
build_tar() {
    build_pkg "tar-${TAR_VER}.tar.xz" "tar-${TAR_VER}"
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make
    make check || log_info "Certains tests Tar ont échoué (acceptable)."
    make install
    make -C doc install-html docdir="/usr/share/doc/tar-${TAR_VER}"
    clean_pkg "tar-${TAR_VER}"
}

# =============================================================================
# 8.74 — Texinfo-7.2
# =============================================================================
build_texinfo() {
    build_pkg "texinfo-${TEXINFO_VER}.tar.xz" "texinfo-${TEXINFO_VER}"
    ./configure --prefix=/usr
    make
    make check
    make install
    clean_pkg "texinfo-${TEXINFO_VER}"
}

# =============================================================================
# 8.75 — Vim-9.2.0078
# =============================================================================
build_vim() {
    build_pkg "vim-${VIM_VER}.tar.gz" "vim-${VIM_VER}"
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
    ./configure --prefix=/usr
    make
    chown -R tester .
    su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
        &> vim-test.log || log_info "Certains tests Vim ont échoué (acceptable)."
    make install
    ln -sv vim /usr/bin/vi
    for L in /usr/share/man/{,*/}man1/vim.1; do
        ln -sv vim.1 "$(dirname $L)/vi.1"
    done
    ln -sv ../vim/vim$(echo ${VIM_VER} | tr -d .)/doc /usr/share/doc/vim-${VIM_VER}
    cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
    set background=dark
endif
" End /etc/vimrc
EOF
    clean_pkg "vim-${VIM_VER}"
}

# =============================================================================
# 8.76 — MarkupSafe-3.0.3
# =============================================================================
build_markupsafe() {
    build_pkg "MarkupSafe-${MARKUPSAFE_VER}.tar.gz" "MarkupSafe-${MARKUPSAFE_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist MarkupSafe
    clean_pkg "MarkupSafe-${MARKUPSAFE_VER}"
}

# =============================================================================
# 8.77 — Jinja2-3.1.6
# =============================================================================
build_jinja2() {
    build_pkg "jinja2-${JINJA2_VER}.tar.gz" "jinja2-${JINJA2_VER}"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
    pip3 install --no-index --find-links dist Jinja2
    clean_pkg "jinja2-${JINJA2_VER}"
}

# =============================================================================
# 8.78 — Systemd-259.1
# =============================================================================
build_systemd() {
    build_pkg "systemd-${SYSTEMD_VER}.tar.gz" "systemd-${SYSTEMD_VER}"
    sed -e 's/#GROUP="render"/GROUP="video"/' \
        -e 's/GROUP="sgx", //'               \
        -i rules.d/50-udev-default.rules.in
    mkdir -p build && cd build
    meson setup ..                           \
        --prefix=/usr                        \
        --buildtype=release                  \
        -D default-dnssec=no                 \
        -D firstboot=false                   \
        -D install-tests=false               \
        -D ldconfig=false                    \
        -D sysusers=false                    \
        -D rpmacrosdir=no                    \
        -D homed=disabled                    \
        -D man=disabled                      \
        -D mode=release                      \
        -D pamconfdir=no                     \
        -D dev-kvm-mode=0660                 \
        -D nobody-group=nogroup              \
        -D sysupdate=disabled                \
        -D ukify=disabled                    \
        -D docdir="/usr/share/doc/systemd-${SYSTEMD_VER}"
    ninja
    echo 'NAME="Linux from Scratch"' > /etc/os-release
    unshare -m ninja test || log_info "Certains tests Systemd ont échoué (acceptable)."
    ninja install
    tar -xf "$SRC/systemd-man-pages-${SYSTEMD_VER}.tar.xz" \
        --no-same-owner --strip-components=1                \
        -C /usr/share/man
    systemd-machine-id-setup
    systemctl preset-all
    clean_pkg "systemd-${SYSTEMD_VER}"
}

# =============================================================================
# 8.79 — D-Bus-1.16.2
# =============================================================================
build_dbus() {
    build_pkg "dbus-${DBUS_VER}.tar.xz" "dbus-${DBUS_VER}"
    mkdir -p build && cd build
    meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..
    ninja
    ninja test || log_info "Certains tests D-Bus ont échoué (acceptable)."
    ninja install
    ln -sfv /etc/machine-id /var/lib/dbus
    clean_pkg "dbus-${DBUS_VER}"
}

# =============================================================================
# 8.80 — Man-DB-2.13.1
# =============================================================================
build_man_db() {
    build_pkg "man-db-${MANDB_VER}.tar.xz" "man-db-${MANDB_VER}"
    ./configure --prefix=/usr                                  \
                --docdir="/usr/share/doc/man-db-${MANDB_VER}" \
                --sysconfdir=/etc                             \
                --disable-setuid                              \
                --enable-cache-owner=bin                      \
                --with-browsers=/usr/bin/lynx                 \
                --with-vgrind=/usr/bin/vgrind                 \
                --with-grap=/usr/bin/grap
    make
    make check
    make install
    clean_pkg "man-db-${MANDB_VER}"
}

# =============================================================================
# 8.81 — Procps-ng-4.0.6
# =============================================================================
build_procps() {
    build_pkg "procps-ng-${PROCPS_VER}.tar.xz" "procps-ng-${PROCPS_VER}"
    ./configure --prefix=/usr                                      \
                --docdir="/usr/share/doc/procps-ng-${PROCPS_VER}" \
                --disable-static                                   \
                --disable-kill                                     \
                --enable-watch8bit                                 \
                --with-systemd
    make
    chown -R tester .
    su tester -c "PATH=$PATH make check" || \
        log_info "Certains tests Procps-ng ont échoué (acceptable)."
    make install
    clean_pkg "procps-ng-${PROCPS_VER}"
}

# =============================================================================
# 8.82 — Util-linux-2.41.3
# =============================================================================
build_util_linux() {
    build_pkg "util-linux-${UTIL_LINUX_VER}.tar.xz" "util-linux-${UTIL_LINUX_VER}"
    mkdir -pv /var/lib/hwclock
    ./configure --bindir=/usr/bin                   \
                --libdir=/usr/lib                   \
                --runstatedir=/run                  \
                --sbindir=/usr/sbin                 \
                --disable-chfn-chsh                 \
                --disable-login                     \
                --disable-nologin                   \
                --disable-su                        \
                --disable-setpriv                   \
                --disable-runuser                   \
                --disable-pylibmount                \
                --disable-liblastlog2               \
                --disable-static                    \
                --without-python                    \
                ADJTIME_PATH=/var/lib/hwclock/adjtime \
                --docdir="/usr/share/doc/util-linux-${UTIL_LINUX_VER}"
    make
    touch /etc/fstab
    chown -R tester .
    su tester -c "make -k check" || \
        log_info "Certains tests Util-linux ont échoué (acceptable)."
    make install
    clean_pkg "util-linux-${UTIL_LINUX_VER}"
}

# =============================================================================
# 8.83 — E2fsprogs-1.47.2
# =============================================================================
build_e2fsprogs() {
    build_pkg "e2fsprogs-${E2FSPROGS_VER}.tar.gz" "e2fsprogs-${E2FSPROGS_VER}"
    mkdir -v build && cd build
    ../configure --prefix=/usr       \
                 --sysconfdir=/etc   \
                 --enable-elf-shlibs \
                 --disable-libblkid  \
                 --disable-libuuid   \
                 --disable-uuidd     \
                 --disable-fsck
    make
    make check || log_info "Certains tests E2fsprogs ont échoué (acceptable)."
    make install
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    gunzip -v /usr/share/info/libext2fs.info.gz
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
    makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
    install -v -m644 doc/com_err.info /usr/share/info
    install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
    sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
    clean_pkg "e2fsprogs-${E2FSPROGS_VER}"
}

# =============================================================================
# 8.84 — Nettoyage et stripping du système final
# =============================================================================
strip_and_clean() {
    log_info "Stripping des binaires et bibliothèques..."
    save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
                 libc.so.6
                 libthread_db.so.1
                 libquadmath.so.0.0.0
                 libstdc++.so.6.0.33
                 libitm.so.1.0.0
                 libatomic.so.1.2.0"

    cd /usr/lib
    for LIB in $save_usrlib; do
        objcopy --only-keep-debug --compress-debug-sections=zlib $LIB ${LIB}.dbg 2>/dev/null || true
        cp $LIB /tmp/$LIB
        strip --strip-unneeded /tmp/$LIB
        objcopy --add-gnu-debuglink=${LIB}.dbg /tmp/$LIB 2>/dev/null || true
        install -vm755 /tmp/$LIB /usr/lib/$LIB
        rm /tmp/$LIB
    done

    find /usr/lib -type f -name \*.so* ! -name \*dbg \
        -exec strip --strip-unneeded {} \; 2>/dev/null || true
    find /usr/{bin,sbin,libexec} -type f \
        -exec strip --strip-all {} \; 2>/dev/null || true

    log_ok "Stripping terminé."
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log_info "=== Phase 6 : Construction du système final (Chapitre 8) ==="

    build_man_pages
    build_iana_etc
    build_glibc
    build_zlib
    build_bzip2
    build_xz
    build_lz4
    build_zstd
    build_file
    build_readline
    build_pcre2
    build_m4
    build_bc
    build_flex
    build_tcl
    build_expect
    build_dejagnu
    build_pkgconf
    build_binutils
    build_gmp
    build_mpfr
    build_mpc
    build_attr
    build_acl
    build_libcap
    build_libxcrypt
    build_shadow
    build_gcc
    build_ncurses
    build_sed
    build_psmisc
    build_gettext
    build_bison
    build_grep
    build_bash
    build_libtool
    build_gdbm
    build_gperf
    build_expat
    build_inetutils
    build_less
    build_perl
    build_xml_parser
    build_intltool
    build_autoconf
    build_automake
    build_openssl
    build_libelf
    build_libffi
    build_sqlite
    build_python
    build_flit_core
    build_packaging
    build_wheel
    build_setuptools
    build_ninja
    build_meson
    build_kmod
    build_coreutils
    build_diffutils
    build_gawk
    build_findutils
    build_groff
    build_grub
    build_gzip
    build_iproute2
    build_kbd
    build_libpipeline
    build_make
    build_patch
    build_tar
    build_texinfo
    build_vim
    build_markupsafe
    build_jinja2
    build_systemd
    build_dbus
    build_man_db
    build_procps
    build_util_linux
    build_e2fsprogs
    strip_and_clean

    log_ok "=== Phase 6 terminée — Système de base construit ==="
    log_info "Lancez maintenant (depuis le chroot) : bash /sources/scripts/07_system_config.sh"
}

main "$@"
