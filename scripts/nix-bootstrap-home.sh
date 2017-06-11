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
XZ_VERSION=5.2.3

DBI_VERSION=1.636       ; DBI_HASH=60f291e5f015550dde71d1858dfe93ba
DBD_SQLITE_VERSION=1.52 ; DBD_SQLITE_HASH=a54c2e8ab74587c3b6f8045fddc5aba5
WWW_CURL_VERSION=4.17   ; WWW_CURL_HASH=997ac81cd6b03b30b36f7cd930474845
NIX_VERSION=1.11.9

export PATH=$NIX_DIR/bin:$PATH
export PKG_CONFIG_PATH=$NIX_DIR/lib/pkgconfig:$PKG_CONFIG_PATH

# TODO fix /usr/bin/ld: cannot find -llzma
#
# TODO fix /usr/bin/ld: /global/home/users/jefdaj/nix-boot/bin/nix-hash: undefined reference to symbol '__pthread_key_create@@GLIBC_2.2.5'
#          /usr/bin/ld: note: '__pthread_key_create@@GLIBC_2.2.5' is defined in DSO /lib64/libpthread.so.0 so try adding it to the linker command line
#          /lib64/libpthread.so.0: could not read symbols: Invalid operation"
#
# things tried:
#   x -pthread at end
#   x -lpthread at end
#   x both together,
#   x removing CPPFLAGS
#   x removing CXXFLAGS (CPPFLAGS should be passed on?)
#   x removing -pthread -lpthread from all but LDFLAGS
#   x running bootstrap.sh in the nix source dir
#   removing flags altogether to see if they're being used at all... seems not?
#   adding flags to ./configure directly
#   adding lib and lib64 to PERL5OPT
#   only using -pthread and/or -lpthread in one set of flags at once
#
# export  LDFLAGS="-I$NIX_DIR/include -L$NIX_DIR/lib -L/lib64 -L/lib -pthread -lpthread"
# export CPPFLAGS="-I$NIX_DIR/include -L$NIX_DIR/lib -L/lib64 -L/lib -pthread -lpthread"
# export CXXFLAGS="-I$NIX_DIR/include -L$NIX_DIR/lib -L/global/software/sl-6.x86_64/modules/langs/gcc/4.8.5/lib64 -L/global/software/sl-6.x86_64/modules/langs/gcc/4.8.5/lib"

# TODO is this right?
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

build_xz() {
  # this is an attempt at solving nix's "no package liblzma found" error
  cd $NIX_DIR
  if [ ! -e xz-${XZ_VERSION}.tar.gz ]; then
    wget "https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz"
  fi
  if [ ! -e $NIX_DIR/lib/liblzma.so ]; then
    tar xzvf xz-*.gz
    cd xz-*
    ./configure --prefix=$NIX_DIR
    make
    make install
  fi
}

build_nix() {
  cd $NIX_DIR
  # if [ ! -e nix-${NIX_VERSION}.tar.bz2 ] ; then
  #   wget http://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.bz2
  # fi
  # if [ ! -e $NIX_DIR/bin/nix-env ] ; then
    # bzip2 -d nix-*bz2
    tar xvf nix-*.tar
    cd nix-*
    # TODO should these be set separately since they'll persist after bootstrapping?
    # export  LDFLAGS="-I$NIX_DIR/include -L$NIX_DIR/lib -L/lib64 -L/lib -pthread -lpthread"
    # patch configure.ac /global/home/users/jefdaj/nix-no-root/configure.patch
    # patch src/nix-hash/local.mk /global/home/users/jefdaj/nix-no-root/nix-hash-local.mk.patch
    # patch src/nix-*/local.mk /global/home/users/jefdaj/nix-no-root/nix-local.mk.patch

    # TODO get liblzma working:
    # TODO patch Makefile.config.in               /global/home/users/jefdaj/nix-no-root/Makefile.config.in.patch

    # TODO put these in one big "-pthread" patch:
    patch src/nix-hash/local.mk            /global/home/users/jefdaj/nix-no-root/nix-hash-local.mk.patch
    patch src/nix-instantiate/local.mk     /global/home/users/jefdaj/nix-no-root/nix-instantiate-local.mk.patch
    patch src/nix-env/local.mk             /global/home/users/jefdaj/nix-no-root/nix-env-local.mk.patch
    patch src/nix-collect-garbage/local.mk /global/home/users/jefdaj/nix-no-root/nix-collect-garbage-local.mk.patch
    patch src/libutil/local.mk             /global/home/users/jefdaj/nix-no-root/nix-libutil-local.mk.patch
    patch src/download-via-ssh/local.mk    /global/home/users/jefdaj/nix-no-root/nix-download-via-ssh-local.mk.patch
    patch local.mk                         /global/home/users/jefdaj/nix-no-root/nix-local.mk.patch

    # from https://github.com/NixOS/nix/issues/566
    # export LD_LIBRARY_PATH="$NIX_DIR/lib:$LD_LIBRARY_PATH"

    ./configure --prefix=$NIX_DIR --with-store-dir=$NIX_DIR/store --localstatedir=$NIX_DIR/var # CXXFLAGS="$CXXFLAGS" GLOBAL_LDFLAGS=-pthread

    # from https://github.com/NixOS/nix/issues/566
    # sed -ri 's@^GLOBAL_CXXFLAGS \+= .*all$@& '"$CXXFLAGS"'@' Makefile
    # echo "GLOBAL_CFLAGS += $CFLAGS" >> Makefile
    # echo "GLOBAL_LDFLAGS += $LDFLAGS" >> Makefile

    make
    # make install exec_prefix=$NIX_DIR
    make install
  # fi
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
  # build_bzip2
  # build_sqlite3
  # build_curl
  # build_dbi
  # build_dbdsqlite
  # build_wwwcurl
  # build_xz
  build_nix
}

main
