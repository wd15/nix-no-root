nix-no-root
===========

Originally forked from [pjotrp/nix-no-root](https://github.com/pjotrp/nix-no-root).
Successfully builds Nix 2.0.4 with no root access as of September 2018.

Unfortunately, the official binary cache won't work with any path except `/nix`.
And since you have to compile anyway, might as well also
fork `nixpkgs` now and use your version to stabilize your builds:

    git clone http://github.com/yourusername/nixpkgs.git
    export NIX_PATH=nixpkgs=$PWD/nixpkgs

(Later, you can rebase from an upstream channel branch)

Then install `config.nix` and edit to your liking.

Finally, run the script. It takes two arguments: a temporary directory for
compiling the bootstrap version, and the final nix directory where everything
will eventually go. The final directory must be the same as in your
`config.nix`. Other args are passed to the last `nix-env` command. You probably
want add `-j` to use all processors. This was my full invocation:

    # provided by the Berkeley cluster environment
    # you may need to find your equivalents
    module load gcc/6.3.0
    module load boost/1.66.0

    ./nix-no-root.sh \
      /clusterfs/rosalind/users/jefdaj/nix-boot /clusterfs/rosalind/users/jefdaj/nix2 \
      -j$(nproc) --keep-going --show-trace 2>&1 | tee nix-no-root.log

Before you start, make sure your `PATH` doesn't reference existing nix binaries.
`NIX_PATH` should include your nixpkgs if applicable though.

So far, some version of the script has worked on the following systems.
Please add yours here, or message me and I will!

| nix version | operating system     | uname -a |
| ----------- | -------------------- | -------- |
| 1.6.1       | CentOS 6             | Linux version 2.6.32-431.17.1.el6.x86_64 (mockbuild@c6b8.bsys.dev.centos.org) (gcc version 4.4.7 20120313 (Red Hat 4.4.7-4) (GCC) ) #1 SMP Wed May 7 23:32:49 UTC 2014 |
| 1.11.9      | Scientific Linux 6.9 | Linux ln002.brc 2.6.32-642.15.1.el6.x86_64 #1 SMP Thu Feb 23 11:19:57 CST 2017 x86_64 x86_64 x86_64 GNU/Linux |
| 2.0.4       | Scientific Linux 7.4 | Linux ln003.brc 3.10.0-693.11.6.el7.x86_64 #1 SMP Wed Jan 3 18:09:42 CST 2018 x86_64 x86_64 x86_64 GNU/Linux |

Things that should work, but I haven't tried:

* install Nix, then install Guix with `nix-env -i guix`
* build on another host with same path + similar architecture and running kernel, then move the binaries
