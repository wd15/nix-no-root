#! /bin/sh
#
# This script creates a working nix in $NIX_DIR, as described on
# https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29

# TODO clarify: it's just the bootstrap, not final nix dir right?
NIX_DIR=$HOME/nix-boot
FEDORA_PKGS='https://pkgs.fedoraproject.org/repo/pkgs'

BZ2_VERSION=1.0.6
CURL_VERSION=7.35.0
SQLITE_YEAR=2017; SQLITE_VERSION=3190200

DBI_VERSION=1.636       ; DBI_HASH=60f291e5f015550dde71d1858dfe93ba
DBD_SQLITE_VERSION=1.52 ; DBD_SQLITE_HASH=a54c2e8ab74587c3b6f8045fddc5aba5
WWW_CURL_VERSION=4.17   ; WWW_CURL_HASH=997ac81cd6b03b30b36f7cd930474845
NIX_VERSION=1.11.9

export PATH=$NIX_DIR/bin:$PATH
export PKG_CONFIG_PATH=$NIX_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export LDFLAGS="-L$NIX_DIR/lib $LDFLAGS"
export CPPFLAGS="-I$NIX_DIR/include $CPPFLAGS"
# TODO is this still right?
# export PERL5OPT="-I$NIX_DIR/lib/perl -I$NIX_DIR/lib64/perl5 -I$NIX_DIR/lib/perl5 -I$NIX_DIR/lib/perl5/site_perl"
export PERL5OPT="-I$NIX_DIR/lib/perl -I$NIX_DIR/lib/perl5/x86_64-linux-thread-multi -I$NIX_DIR/lib/perl5 -I$NIX_DIR/lib/perl5/site_perl"

mkdir -p $NIX_DIR

build_curl() {
  cd $NIX_DIR
  if [ ! -e curl-${CURL_VERSION}.tar.lzma ] ; then
    wget http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.lzma
  fi
  if [ ! -e $NIX_DIR/bin/curl ]; then
     lzma -d curl*.lzma
     tar xvf curl*tar
     cd curl-*
     ./configure --prefix=$NIX_DIR
     make
     make install
  fi
}

# TODO how to set the version here?
build_sqlite3() {
  cd $NIX_DIR
  if [ ! -e sqlite-autoconf-${SQLITE_VERSION}.tar.gz ] ; then
    wget http://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
  fi
  if [ ! -e $NIX_DIR/bin/sqlite3 ]; then
     tar xvzf sqlite*tar.gz
     cd sqlite-*
     ./configure --prefix=$NIX_DIR
     make
     make install
  fi
}

build_dbi() {
  cd $NIX_DIR
  if [ ! -e DBI-${DBI_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-DBI/DBI-${DBI_VERSION}.tar.gz/${DBI_HASH}/DBI-${DBI_VERSION}.tar.gz"
  fi
  if [ ! -e $NIX_DIR/bin/dbiproxy ] ; then
    tar xvzf DBI-*.tar.gz 
    cd DBI-*
    perl Makefile.PL INSTALL_BASE=$NIX_DIR
    make
    make install
  fi
}

build_dbdsqlite() {
  cd $NIX_DIR
  if [ ! -e DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-DBD-SQLite/DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz/${DBD_SQLITE_HASH}/DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz"
  fi
  # TODO is this path still right?
  # ~/nix-boot/lib/perl5/x86_64-linux-thread-multi/DBI
  # if [ ! -e $NIX_DIR/lib64/perl5/DBD/SQLite.pm ]; then
  if [ ! -e $NIX_DIR/lib/perl5/x86_64-linux-thread-multi/DBD/SQLite.pm ]; then
    tar xvzf DBD-SQLite-*.gz
    cd DBD-*
    perl Makefile.PL INSTALL_BASE=$NIX_DIR
    make
    make install
  fi
}

build_wwwcurl() {
  cd $NIX_DIR
  if [ ! -e WWW-Curl-${WWW_CURL_VERSION}.tar.gz ] ; then
    wget --no-check-certificate "${FEDORA_PKGS}/perl-WWW-Curl/WWW-Curl-${WWW_CURL_VERSION}.tar.gz/${WWW_CURL_HASH}/WWW-Curl-${WWW_CURL_VERSION}.tar.gz"
  fi
  # TODO is this path still right?
  if [ ! -e $NIX_DIR/lib/perl5/x86_64-linux-thread-multi/WWW/Curl.pm ]; then
    tar xvzf WWW-Curl-*.gz
    cd WWW-*
    perl Makefile.PL INSTALL_BASE=$NIX_DIR
    make
    make install
  fi
}

build_bzip2() {
  cd $NIX_DIR
  if [ ! -e bzip2-${BZ2_VERSION}.tar.gz ] ; then
    wget http://bzip.org/${BZ2_VERSION}/bzip2-${BZ2_VERSION}.tar.gz
  fi
  if [ ! -e $NIX_DIR/lib/libbz2.so.${BZ2_VERSION} ]; then
    tar xvzf bzip2-${BZ2_VERSION}.tar.gz
    cd bzip2*
    make -f Makefile-libbz2_so
    make install PREFIX=$NIX_DIR
    # TODO what to do about the 1.0?
    cp libbz2.so.1.0 libbz2.so.${BZ2_VERSION} $NIX_DIR/lib
  fi
}

build_nix() {
  cd $NIX_DIR
  if [ ! -e nix-${NIX_VERSION}.tar.bz2 ] ; then
    wget http://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.bz2
  fi
  if [ ! -e $NIX_DIR/bin/nix-env ] ; then
    bzip2 -d nix-*bz2
    tar xvf nix-*.tar
    cd nix-*
    # TODO should these be set separately since they'll persist after bootstrapping?
    ./configure --prefix=$NIX_DIR --with-store-dir=$NIX_DIR/store --localstatedir=$NIX_DIR/var
    make
    make install
  fi
}

# $NIX_DIR/bin/nix-env --version
# [ $? -ne 0 ] && exit 1
# 
# echo "Success. To proceed you may want to set"
# echo 'export PATH=$NIX_DIR/bin:$PATH'
# echo 'export PKG_CONFIG_PATH=$NIX_DIR/lib/pkgconfig:$PKG_CONFIG_PATH'
# echo 'export LDFLAGS="-L$NIX_DIR/lib $LDFLAGS"'
# echo 'export CPPFLAGS="-I$NIX_DIR/include $CPPFLAGS"'
# echo 'export PERL5OPT="-I$NIX_DIR/lib/perl -I$NIX_DIR/lib64/perl5 -I$NIX_DIR/lib/perl5 -I$NIX_DIR/lib/perl5/site_perl"'
# echo '  and follow https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29'

main() {
  # set -E
  build_bzip2
  build_sqlite3
  build_curl
  build_dbi
  build_dbdsqlite
  build_wwwcurl

  # TODO fix "no package liblzma found"... by downloading it? or sending a support email?
  # build_nix
}

main
