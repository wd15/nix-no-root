nix-no-root
===========

My fork of [pjotrp/nix-no-root][1], which diverged considerably as I tried to
get the latest Nix to build. It takes two arguments: a temporary directory for
compiling the first time, and the directory where everything should go once it
works. For example, this is what I used:

    nix-no-root.sh /global/home/users/jefdaj/nix-boot /clusterfs/rosalind/users/jefdaj/nix

If the system has gcc, Perl and a few other build tools it may be possible to
bootstrap on the target system using nix-no-root.sh. Alternatively, provided
the path is the same, you can actually build on any host with a similar
architecture and running kernel and move the binaries across. Nix is
self-contained and depends on very little. That is important to know!

The basic information came from the [Nix wiki][2] (link now broken).

So far, this is the most successful bootstrap route I tried for Nix,
and I have tried quite a few ways over time. For Guix the upside is
that if Nix works you can simply install Guix from a Nix package.
Very easy. 

So far, some version of the script has worked on the following systems.
Please add yours here, or message me and I will!

nix version operating system              uname -a
----------- ----------------              --------
1.6.1       CentOS 6                      Linux version 2.6.32-431.17.1.el6.x86_64 (mockbuild@c6b8.bsys.dev.centos.org) (gcc version 4.4.7 20120313 (Red Hat 4.4.7-4) (GCC) ) #1 SMP Wed May 7 23:32:49 UTC 2014
1.11.9      Scientific Linux 6.9 (Carbon) Linux ln002.brc 2.6.32-642.15.1.el6.x86_64 #1 SMP Thu Feb 23 11:19:57 CST 2017 x86_64 x86_64 x86_64 GNU/Linux

# NixPkgs

The easiest way to handle nixpkgs is to checkout a git repository and
pass it in to nix-env. Because nix builds dependencies on the full
paths it is not possible to use the pre-built binaries anyway.

    ~/nix-boot/bin/nix-env -f nixpkgs/ -i guix

Another advantage of using a git repository is that you can easily
stabilize on the build set you want to deploy (elsewhere). At the
moment we use a branch for our lab and a branch for (cloud)biolinux.

# Guix

GNU Guix is a Nix package which can be installed with

    env TMPDIR=/var/tmp/pprins/ ~/nix-boot/bin/nix-env -f nixpkgs/ -i guix 

in my opinion this is the easiest way to bootstrap Guix on an existing
Linux system without root. Currently I can do

   ~/nix/store/1qjma0ik7y2lcsgdni9y0hjk435jhhf9-guix-0.3/bin/guix-daemon --listen=$HOME/tmp/guix
   env GUIX_DAEMON_SOCKET=$HOME/tmp/guix nix/store/1qjma0ik7y2lcsgdni9y0hjk435jhhf9-guix-0.3/bin/guix package -i vim
   guix package: error: build failed: creating directory `/nix': Permission denied
 
[1]: https://github.com/pjotrp/nix-no-root
[2]: https://nixos.org/wiki/How_to_install_nix_in_home_%28on_another_distribution%29
