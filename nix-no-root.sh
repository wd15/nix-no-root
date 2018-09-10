#! /bin/sh

usage="Usage: nix-no-root.sh /path/to/bootstrap/dir /path/to/final/nix/dir [nix-env args]"
[[ $# -ge 2 ]] || (echo "$usage"; exit 1)
BOOTSTRAP_DIR="$1"; shift
NIX_DIR="$1" ; shift

# as of today, 2.1 carries a bug that messes up fixed-derivation paths:
# https://github.com/NixOS/nix/issues/2393
NIX_VERSION=2.0.4
LIBSECCOMP_VERSION=2.3.3

export PATH=$BOOTSTRAP_DIR/bin:$PATH
export PKG_CONFIG_PATH=$BOOTSTRAP_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export TMPDIR=$NIX_DIR/tmp
export LD_LIBRARY_PATH=$BOOTSTRAP_DIR/lib:$LD_LIBRARY_PATH
# export LDFLAGS="-L$BOOTSTRAP_DIR/lib $LDFLAGS -static"

mkdir -p $BOOTSTRAP_DIR || (echo "failed to create $BOOTSTRAP_DIR" && exit 1)
mkdir -p $TMPDIR   || (echo "failed to create $TMPDIR"   && exit 1)

build_libbrotli() {
  # TODO download a specific version?
  cd $BOOTSTRAP_DIR
  if [[ ! -a lib/libbrotlidec.a ]]; then
    [[ -d libbrotli ]] || git clone http://github.com/bagder/libbrotli
    cd libbrotli
    ./autogen.sh
    ./configure --prefix=$BOOTSTRAP_DIR
    make
    make install
  fi
  export PKG_CONFIG_PATH=$BOOTSTRAP_DIR/libbrotli:$PKG_CONFIG_PATH
}

build_libseccomp() {
  cd $BOOTSTRAP_DIR
  if [[ ! -e lib/libseccomp.so ]]; then
    baseurl="https://github.com/seccomp/libseccomp/releases/download"
    wget "${baseurl}/v${LIBSECCOMP_VERSION}/libseccomp-${LIBSECCOMP_VERSION}.tar.gz"
    tar xvzf libseccomp-${LIBSECCOMP_VERSION}.tar.gz
    cd libseccomp*
    ./configure --prefix=$BOOTSTRAP_DIR
    make
    make install
  fi
  export PKG_CONFIG_PATH=$BOOTSTRAP_DIR/libseccomp-${LIBSECCOMP_VERSION}:$PKG_CONFIG_PATH
}

build_nix() {
  build_libbrotli
  build_libseccomp
  cd $BOOTSTRAP_DIR
  if [ ! -e $BOOTSTRAP_DIR/bin/nix-env ] ; then
    if [ ! -d nix-${NIX_VERSION} ] ; then
      wget http://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.bz2
      bzip2 -d nix-${NIX_VERSION}.tar.bz2
      tar xvf nix-${NIX_VERSION}.tar
    fi
    cd nix-*
    # workaround for a bug when nix store is on an nfs filesystem
    # see https://github.com/NixOS/nixpkgs/issues/29778
    # TODO find from script path
    patch src/libstore/local-store.cc /global/home/users/jefdaj/nix-no-root/local-store.patch
    ./configure --prefix=$BOOTSTRAP_DIR --with-store-dir=$NIX_DIR/store --localstatedir=$NIX_DIR/var
    LDFLAGS=-static make
    make install
  fi
}

nix_build_nix() {
  export PATH=$BOOTSTRAP_DIR/bin:$PATH
  export PKG_CONFIG_PATH=$BOOTSTRAP_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
  export LDFLAGS="-L$BOOTSTRAP_DIR/lib $LDFLAGS"
  export CPPFLAGS="-I$BOOTSTRAP_DIR/include $CPPFLAGS"
  $BOOTSTRAP_DIR/bin/nix-env -i nix $@
  # module load boost/1.66.0
  # module load gcc/6.3.0
  # ldp=$LD_LIBRARY_PATH
  # lp=$LIBRARY_PATH
  # unset LD_LIBRARY_PATH
  # unset LIBRARY_PATH
  # export LIBRARY_PATH=$lp LD_LIBRARY_PATH=$ldp
  # LD_LIBRARY_PATH= LIBRARY_PATH= LDFLAGS= CPPFLAGS= PKG_CONFIG_PATH= $BOOTSTRAP_DIR/bin/nix-env -i nix $@
}

main() {
  cd $BOOTSTRAP_DIR
  set -E
  build_nix && nix_build_nix $@
}

main $@
