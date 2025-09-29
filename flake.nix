{
  description = "Fleet Toolkit + Coordinate (multi-output flake)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAll = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);
  in {
    ############################################################################
    # Packages
    ############################################################################
    packages = forAll (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # 1) Toolkit (meta-package of common CLIs)
        install-toolkit = pkgs.buildEnv {
          name = "install-toolkit";
          paths = with pkgs; [
            coreutils gawk gnused findutils
            curl wget rsync git
            jq yq fastfetch
            iproute2 iptables nftables
            nmap masscan
            htop tmux ripgrep fd
            socat netcat tcpdump
            unzip zip xz
          ];
        };

        # 2) Coordinate
        coordinate = pkgs.buildGoModule {
          pname = "coordinate";
          version = "1.0.0";
          src = pkgs.lib.cleanSource ./coordinate;

          # Pin a Go version available in nixpkgs. Use go_1_21 (or go_1_22 if you prefer).
          go = pkgs.go_1_25;

          # Ignore any checked-in vendor/; let Nix vendor from go.mod/go.sum.
          postPatch = ''
            find . -type d -name vendor -prune -exec rm -rf {} +
          '';

          # Replace with the hash you observed from the first successful vendor step.
          vendorHash = "sha256-xNWQNH+rP6YjEM/tU7y08ccRdYKkmGSZ2/b34bhrfCU=";

          # If your main package lives in a subdir, uncomment:
          # subPackages = [ "cmd/coordinate" ];
        };

      }
    );

    ############################################################################
    # Apps (nix run .#coordinate)
    ############################################################################
    apps = forAll (system: {
      coordinate = {
        type = "app";
        program = "${self.packages.${system}.coordinate}/bin/coordinate";
      };
      # optional: set default app
      # default = self.apps.${system}.coordinate;
    });
  };
}

