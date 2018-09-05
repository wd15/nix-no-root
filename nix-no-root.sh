#! /bin/sh
 
# This script compiles a temporary Nix in $BOOT_DIR using standard Unix tools,
# then uses that to install a "proper" version in $NIX_DIR. The first two
# arguments are bootstrap dir and final nix dir; any others are passed to
# nix-env in the second step. It works as of July 2017 (Nix 1.11.9), but if
# that was a long time ago you may need to update package versions below.

usage="Usage: nix-no-root.sh /path/to/bootstrap/dir /path/to/final/nix/dir [nix-env args]"
[[ $# -ge 2 ]] || (echo "$usage"; exit 1)
BOOT_DIR="$1"; shift
NIX_DIR="$1" ; shift

FEDORA_PKGS='https://pkgs.fedoraproject.org/repo/pkgs'
BZ2_VERSION=1.0.6
CURL_VERSION=7.35.0
SQLITE_YEAR=2017; SQLITE_VERSION=3190200
XZ_VERSION=5.2.3
DBI_VERSION=1.636       ; DBI_HASH=60f291e5f015550dde71d1858dfe93ba
DBD_SQLITE_VERSION=1.52 ; DBD_SQLITE_HASH=a54c2e8ab74587c3b6f8045fddc5aba5
WWW_CURL_VERSION=4.17   ; WWW_CURL_HASH=997ac81cd6b03b30b36f7cd930474845
NIX_VERSION=1.11.9

export PATH=$BOOT_DIR/bin:$PATH
export PKG_CONFIG_PATH=$BOOT_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export TMPDIR=$NIX_DIR/tmp

# these didn't work for me, maybe because of centos? had to patch nix src files instead
# export  LDFLAGS="-I$BOOT_DIR/include -L$BOOT_DIR/lib -L/lib64 -L/lib -pthread -lpthread"
# export CPPFLAGS="-I$BOOT_DIR/include -L$BOOT_DIR/lib -L/lib64 -L/lib -pthread -lpthread"
export PERL5OPT="-I$BOOT_DIR/lib/perl -I$BOOT_DIR/lib/perl5/x86_64-linux-thread-multi -I$BOOT_DIR/lib/perl5 -I$BOOT_DIR/lib/perl5/site_perl"

mkdir -p $BOOT_DIR || (echo "failed to create $BOOT_DIR" && exit 1)
mkdir -p $TMPDIR   || (echo "failed to create $TMPDIR"   && exit 1)

build_curl() {
  cd $BOOT_DIR
  if [ ! -e curl-${CURL_VERSION}.tar.lzma ] ; then
    wget http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.lzma
  fi
  if [ ! -e $BOOT_DIR/bin/curl ]; then
     lzma -d curl*.lzma
     tar xvf curl*tar
     cd curl-*
     ./configure --prefix=$BOOT_DIR
     make
     make install
  fi
}

build_sqlite3() {
  cd $BOOT_DIR
  if [ ! -e sqlite-autoconf-${SQLITE_VERSION}.tar.gz ] ; then
    wget http://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
  fi
  if [ ! -e $BOOT_DIR/bin/sqlite3 ]; then
     tar xvzf sqlite*tar.gz
     cd sqlite-*
     ./configure --prefix=$BOOT_DIR
     make
     make install
  fi
}

build_dbi() {
  cd $BOOT_DIR
  if [ ! -e DBI-${DBI_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-DBI/DBI-${DBI_VERSION}.tar.gz/${DBI_HASH}/DBI-${DBI_VERSION}.tar.gz"
  fi
  if [ ! -e $BOOT_DIR/bin/dbiproxy ] ; then
    tar xvzf DBI-*.tar.gz 
    cd DBI-*
    perl Makefile.PL INSTALL_BASE=$BOOT_DIR
    make
    make install
  fi
}

build_dbdsqlite() {
  cd $BOOT_DIR
  if [ ! -e DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-DBD-SQLite/DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz/${DBD_SQLITE_HASH}/DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz"
  fi
  if [ ! -e $BOOT_DIR/lib/perl5/x86_64-linux-thread-multi/DBD/SQLite.pm ]; then
    tar xvzf DBD-SQLite-*.gz
    cd DBD-*
    perl Makefile.PL INSTALL_BASE=$BOOT_DIR
    make
    make install
  fi
}

build_wwwcurl() {
  cd $BOOT_DIR
  if [ ! -e WWW-Curl-${WWW_CURL_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-WWW-Curl/WWW-Curl-${WWW_CURL_VERSION}.tar.gz/${WWW_CURL_HASH}/WWW-Curl-${WWW_CURL_VERSION}.tar.gz"
  fi
  if [ ! -e $BOOT_DIR/lib/perl5/x86_64-linux-thread-multi/WWW/Curl.pm ]; then
    tar xvzf WWW-Curl-*.gz
    cd WWW-*
    perl Makefile.PL INSTALL_BASE=$BOOT_DIR
    make
    make install
  fi
}

build_bzip2() {
  cd $BOOT_DIR
  if [ ! -e bzip2-${BZ2_VERSION}.tar.gz ] ; then
    wget http://bzip.org/${BZ2_VERSION}/bzip2-${BZ2_VERSION}.tar.gz
  fi
  if [ ! -e $BOOT_DIR/lib/libbz2.so.${BZ2_VERSION} ]; then
    tar xvzf bzip2-${BZ2_VERSION}.tar.gz
    cd bzip2*
    make -f Makefile-libbz2_so
    make install PREFIX=$BOOT_DIR
    cp libbz2.so.1.0 libbz2.so.${BZ2_VERSION} $BOOT_DIR/lib
  fi
}

build_xz() {
  # this is an attempt at solving nix's "no package liblzma found" error
  cd $BOOT_DIR
  if [ ! -e xz-${XZ_VERSION}.tar.gz ]; then
    wget "https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz"
  fi
  if [ ! -e $BOOT_DIR/lib/liblzma.so ]; then
    tar xzvf xz-*.gz
    cd xz-*
    ./configure --prefix=$BOOT_DIR
    make
    make install
  fi
}

build_nix() {
  build_bzip2
  build_sqlite3
  build_curl
  build_dbi
  build_dbdsqlite
  build_wwwcurl
  build_xz
  cd $BOOT_DIR
  if [ ! -e $BOOT_DIR/bin/nix-env ] ; then
    if [ ! -e nix-${NIX_VERSION}.tar.bz2 ] ; then
      wget http://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.bz2
    fi
    bzip2 -d nix-*bz2
    tar xvf nix-*.tar
    cd nix-*
    # TODO avoid full path here, maybe using the script path
    patch local.mk /global/home/users/jefdaj/nix-no-root/nix-local.mk.patch
    ./configure --prefix=$BOOT_DIR --with-store-dir=$NIX_DIR/store --localstatedir=$NIX_DIR/var
    make
    make install
  fi
}

nix_build_nix() {
  export PATH=$BOOT_DIR/bin:$PATH
  export PKG_CONFIG_PATH=$BOOT_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
  export LDFLAGS="-L$BOOT_DIR/lib $LDFLAGS"
  export CPPFLAGS="-I$BOOT_DIR/include $CPPFLAGS"
  export PERL5OPT="-I$BOOT_DIR/lib/perl -I$BOOT_DIR/lib64/perl5 -I$BOOT_DIR/lib/perl5 -I$BOOT_DIR/lib/perl5/site_perl"
  $BOOT_DIR/bin/nix-env -i nix $@
}

main() {
  cd $BOOT_DIR
  build_nix && nix_build_nix $@
}

main $@
