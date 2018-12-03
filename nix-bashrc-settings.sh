# TODO repo dir variable?
export NIX_STATE_DIR=/clusterfs/rosalind/users/jefdaj/nix2/var
export NIX_STORE_DIR=/clusterfs/rosalind/users/jefdaj/nix2/store

if [ -n "$HOME" ] && [ -n "$USER" ]; then
    __savedpath="$PATH"
    export PATH=$NIX_STORE_DIR/81qcskn2af3nhrpipvkl3qdbbrsi12d8-coreutils-8.29/bin

    # Set up the per-user profile.
    # This part should be kept in sync with nixpkgs:nixos/modules/programs/shell.nix

    NIX_LINK=$HOME/.nix-profile

    NIX_USER_PROFILE_DIR=$NIX_STATE_DIR/nix/profiles/per-user/$USER

    mkdir -m 0755 -p "$NIX_USER_PROFILE_DIR"

    if [ "$(stat --printf '%u' "$NIX_USER_PROFILE_DIR")" != "$(id -u)" ]; then
        echo "Nix: WARNING: bad ownership on "$NIX_USER_PROFILE_DIR", should be $(id -u)" >&2
    fi

    if [ -w "$HOME" ]; then
        if ! [ -L "$NIX_LINK" ]; then
            echo "Nix: creating $NIX_LINK" >&2
            if [ "$USER" != root ]; then
                if ! ln -s "$NIX_USER_PROFILE_DIR"/profile "$NIX_LINK"; then
                    echo "Nix: WARNING: could not create $NIX_LINK -> $NIX_USER_PROFILE_DIR/profile" >&2
                fi
            else
                # Root installs in the system-wide profile by default.
                ln -s $NIX_STATE_DIR/nix/profiles/default "$NIX_LINK"
            fi
        fi

        # Subscribe the user to the unstable Nixpkgs channel by default.
        # if [ ! -e "$HOME/.nix-channels" ]; then
        #     echo "https://nixos.org/channels/nixpkgs-unstable nixpkgs" > "$HOME/.nix-channels"
        # fi

        # Create the per-user garbage collector roots directory.
        __user_gcroots=$NIX_STATE_DIR/nix/gcroots/per-user/"$USER"
        mkdir -m 0755 -p "$__user_gcroots"
        if [ "$(stat --printf '%u' "$__user_gcroots")" != "$(id -u)" ]; then
            echo "Nix: WARNING: bad ownership on $__user_gcroots, should be $(id -u)" >&2
        fi
        unset __user_gcroots

        # Set up a default Nix expression from which to install stuff.
        __nix_defexpr="$HOME"/.nix-defexpr
        [ -L "$__nix_defexpr" ] && rm -f "$__nix_defexpr"
        mkdir -m 0755 -p "$__nix_defexpr"
        if [ "$USER" != root ] && [ ! -L "$__nix_defexpr"/channels_root ]; then
            ln -s $NIX_STATE_DIR/nix/profiles/per-user/root/channels "$__nix_defexpr"/channels_root
        fi
        unset __nix_defexpr
    fi

    # Append ~/.nix-defexpr/channels/nixpkgs to $NIX_PATH so that
    # <nixpkgs> paths work when the user has fetched the Nixpkgs
    # channel.
    # export NIX_PATH="${NIX_PATH:+$NIX_PATH:}nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs"
    export NIX_PATH="nixpkgs=$HOME/nixpkgs"

    # Set up environment.
    # This part should be kept in sync with nixpkgs:nixos/modules/programs/environment.nix
    NIX_PROFILES="$NIX_STATE_DIR/nix/profiles/default $NIX_USER_PROFILE_DIR"

    # Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
    if [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    elif [ -e /etc/ssl/ca-bundle.pem ]; then # openSUSE Tumbleweed
        export NIX_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem
    elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
        export NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
    elif [ -e "$NIX_LINK/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in Nix profile
        export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ssl/certs/ca-bundle.crt"
    elif [ -e "$NIX_LINK/etc/ca-bundle.crt" ]; then # old cacert in Nix profile
        export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ca-bundle.crt"
    fi

    if [ -n "${MANPATH}" ]; then
        export MANPATH="$NIX_LINK/share/man:$MANPATH"
    fi

    export PATH="$NIX_LINK/bin:$__savedpath"
    unset __savedpath NIX_LINK NIX_USER_PROFILE_DIR NIX_PROFILES
fi
