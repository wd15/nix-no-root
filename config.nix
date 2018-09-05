# Install like this:
#   mkdir $HOME/.nixpkgs
#   cp config.nix $HOME/.nixpkgs/config.nix
# Then edit to your preferred nix path. Must match the script invocation!

pkgs:
 {
   packageOverrides = self: {
     nix = self.nix.override {
       storeDir = "/home/yourusername/nix/store";
       stateDir = "/home/yourusername/nix/var";
     };
   };
 }
