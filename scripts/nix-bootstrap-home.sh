#! /bin/sh
#
# This script creates a working nix in $HOME, as described on
# https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29

NIX_BOOT_DIR=$HOME/nix-boot

mkdir -p $NIX_BOOT_DIR
cd $NIX_BOOT_DIR

if [ ! -e nix-1.6.1.tar.xz ] ; then
wget http://nixos.org/releases/nix/nix-1.6.1/nix-1.6.1.tar.xz
fi
if [ ! -e bzip2-1.0.6.tar.gz ] ; then
wget http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
fi
if [ ! -e curl-7.35.0.tar.lzma ] ; then
wget http://curl.haxx.se/download/curl-7.35.0.tar.lzma
fi
if [ ! -e sqlite-autoconf-3080300.tar.gz ] ; then
wget http://www.sqlite.org/2014/sqlite-autoconf-3080300.tar.gz
fi
if [ ! -e DBI-1.631.tar.gz ] ; then
# wget http://search.cpan.org/CPAN/authors/id/T/TI/TIMB/DBI-1.631.tar.gz
wget --no-check-certificate https://pkgs.fedoraproject.org/repo/pkgs/perl-DBI/DBI-1.631.tar.gz/444d3c305e86597e11092b517794a840/DBI-1.631.tar.gz
fi
if [ ! -e DBD-SQLite-1.40.tar.gz ] ; then
wget --no-check-certificate https://pkgs.fedoraproject.org/repo/pkgs/perl-DBD-SQLite/DBD-SQLite-1.40.tar.gz/b9876882186499583428b14cf5c0e29c/DBD-SQLite-1.40.tar.gz
fi
if [ ! -e WWW-Curl-4.17.tar.gz ] ; then
wget --no-check-certificate https://pkgs.fedoraproject.org/repo/pkgs/perl-WWW-Curl/WWW-Curl-4.17.tar.gz/997ac81cd6b03b30b36f7cd930474845/WWW-Curl-4.17.tar.gz
fi

export PATH=$NIX_BOOT_DIR/bin:$PATH
export PKG_CONFIG_PATH=$NIX_BOOT_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export LDFLAGS="-L$NIX_BOOT_DIR/lib $LDFLAGS"
export CPPFLAGS="-I$NIX_BOOT_DIR/include $CPPFLAGS"
export PERL5OPT="-I$NIX_BOOT_DIR/lib/perl -I$NIX_BOOT_DIR/lib64/perl5 -I$NIX_BOOT_DIR/lib/perl5 -I$NIX_BOOT_DIR/lib/perl5/site_perl"

if [ ! -e $NIX_BOOT_DIR/lib/libbz2.so.1.0.6 ]; then
  cd $NIX_BOOT_DIR
  tar xvzf bzip2-1.0.6.tar.gz
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

