#! /bin/sh
#
# This script creates a working nix in $HOME, as described on
# https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29

NIX_BOOT_DIR=$HOME/nix-boot

NIX_VERSION=1.6.1
BZ2_VERSION=1.0.6
CURL_VERSION=7.35.0
DBI_VERSION=1.631
DBD_SQLITE_VERSION=1.40
WWW_CURL_VERSION=4.17

mkdir -p $NIX_BOOT_DIR
cd $NIX_BOOT_DIR

# TODO switch to gz
if [ ! -e nix-$NIX_VERSION.tar.xz ] ; then
wget http://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.xz
fi
if [ ! -e bzip2-${BZ2_VERSION}.tar.gz ] ; then
wget http://bzip.org/${BZ2_VERSION}/bzip2-${BZ2_VERSION}.tar.gz
fi
if [ ! -e curl-${CURL_VERSION}.tar.lzma ] ; then
wget http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.lzma
fi
# TODO how to set the version here?
if [ ! -e sqlite-autoconf-3080300.tar.gz ] ; then
wget http://www.sqlite.org/2014/sqlite-autoconf-3080300.tar.gz
fi
if [ ! -e DBI-${DBI_VERSION}.tar.gz ] ; then
wget -r --no-check-certificate --no-parent -A "DBI-${DBI_VERSION}.tar.gz" "https://pkgs.fedoraproject.org/repo/pkgs/perl-DBI/DBI-${DBI_VERSION}.tar.gz/"
fi
if [ ! -e DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz ] ; then
wget -r --no-check-certificate --no-parent -A "DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz" "https://pkgs.fedoraproject.org/repo/pkgs/perl-DBD-SQLite/DBD-SQLite-${DBD_SQLITE_VERSION}.tar.gz/"
fi
if [ ! -e WWW-Curl-${WWW_CURL_VERSION}.tar.gz ] ; then
wget -r --no-check-certificate --no-parent -A "WWW-Curl-${WWW_CURL_VERSION}.tar.gz" "https://pkgs.fedoraproject.org/repo/pkgs/perl-WWW-Curl/WWW-Curl-${WWW_CURL_VERSION}.tar.gz/"
fi

export PATH=$NIX_BOOT_DIR/bin:$PATH
export PKG_CONFIG_PATH=$NIX_BOOT_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export LDFLAGS="-L$NIX_BOOT_DIR/lib $LDFLAGS"
export CPPFLAGS="-I$NIX_BOOT_DIR/include $CPPFLAGS"
export PERL5OPT="-I$NIX_BOOT_DIR/lib/perl -I$NIX_BOOT_DIR/lib64/perl5 -I$NIX_BOOT_DIR/lib/perl5 -I$NIX_BOOT_DIR/lib/perl5/site_perl"

if [ ! -e $NIX_BOOT_DIR/lib/libbz2.so.1.0.6 ]; then
  cd $NIX_BOOT_DIR
  tar xvzf bzip2-${BZ2_VERSION}.tar.gz
  cd bzip2*
  make -f Makefile-libbz2_so
  make install PREFIX=$HOME/nix-boot
  cp libbz2.so.1.0 libbz2.so.1.0.6 $HOME/nix-boot/lib
fi


if [ ! -e $NIX_BOOT_DIR/bin/curl ]; then
   cd $NIX_BOOT_DIR
   lzma -d curl*.lzma
   tar xvf curl*tar
   cd curl-*
   ./configure --prefix=$NIX_BOOT_DIR
   make
   make install
fi

if [ ! -e $NIX_BOOT_DIR/bin/sqlite3 ]; then
   cd $NIX_BOOT_DIR
   tar xvzf sqlite*tar.gz
   cd sqlite-*
   ./configure --prefix=$NIX_BOOT_DIR
   make
   make install
fi

if [ ! -e $NIX_BOOT_DIR/bin/dbiproxy ] ; then
  cd $NIX_BOOT_DIR
  tar xvzf DBI-*.tar.gz 
  cd DBI-*
  perl Makefile.PL PREFIX=$HOME/nix-boot
  make
  make install
fi

if [ ! -e $NIX_BOOT_DIR/lib64/perl5/DBD/SQLite.pm ]; then
  cd $NIX_BOOT_DIR
  tar xvzf DBD-SQLite-*.gz
  cd DBD-*
  perl Makefile.PL PREFIX=$HOME/nix-boot
  make
  make install
fi

if [ ! -e $NIX_BOOT_DIR/lib64/perl5/WWW/Curl.pm ]; then
  cd $NIX_BOOT_DIR
  tar xvzf WWW-Curl-*.gz
  cd WWW-*
  perl Makefile.PL PREFIX=$HOME/nix-boot
  make
  make install
fi

if [ ! -e $NIX_BOOT_DIR/bin/nix-env ] ; then
  cd $NIX_BOOT_DIR
  xz -d nix-*xz
  tar xvf nix-*.tar
  cd nix-*
  ./configure --prefix=$HOME/nix-boot --with-store-dir=$HOME/nix/store --localstatedir=$HOME/nix/var
  make
  make install
fi

$NIX_BOOT_DIR/bin/nix-env --version
[ $? -ne 0 ] && exit 1

echo "Success. To proceed you may want to set"
echo 'export PATH=$HOME/nix-boot/bin:$PATH'
echo 'export PKG_CONFIG_PATH=$HOME/nix-boot/lib/pkgconfig:$PKG_CONFIG_PATH'
echo 'export LDFLAGS="-L$HOME/nix-boot/lib $LDFLAGS"'
echo 'export CPPFLAGS="-I$HOME/nix-boot/include $CPPFLAGS"'
echo 'export PERL5OPT="-I$HOME/nix-boot/lib/perl -I$HOME/nix-boot/lib64/perl5 -I$HOME/nix-boot/lib/perl5 -I$HOME/nix-boot/lib/perl5/site_perl"'
echo '  and follow https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29'
