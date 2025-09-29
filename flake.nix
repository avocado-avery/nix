{
  description = "Fleet Toolkit + Coordinate";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAll = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);
  in {
    packages = forAll (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        # existing toolkit
        toolkit = pkgs.buildEnv {
          name = "fleet-toolkit";
          paths = with pkgs; [
            coreutils gawk gnused findutils curl wget rsync git
            jq yq fastfetch iproute2 iptables nftables
            nmap masscan htop tmux ripgrep fd socat netcat tcpdump
            unzip zip xz
          ];
        };

        # NEW: coordinate from ./coordinate-root
        coordinate = pkgs.buildGoModule {
          pname = "coordinate";
          version = "1.0.0";
          src = pkgs.lib.cleanSource ./coordinate-root;

          # Go >= 1.21 (pick one that exists in your pinned nixpkgs)
          go = pkgs.go_1_25;

          # ignore any checked-in vendor/ dir; Nix re-vendors from go.mod/sum
          postPatch = ''
            find . -type d -name vendor -prune -exec rm -rf {} +
          '';

          # Use the vendor hash you observed earlier; if unsure, set null,
          # build once, copy the "got: sha256-..." into this field, and rebuild.
          vendorHash = "sha256-xNWQNH+rP6YjEM/tU7y08ccRdYKkmGSZ2/b34bhrfCU=";

          # If your main package is in a subdir, uncomment:
          # subPackages = [ "cmd/coordinate" ];
        };

        default = self.packages.${system}.toolkit;
      }
    );

    apps = forAll (system: {
      coordinate = {
        type = "app";
        program = "${self.packages.${system}.coordinate}/bin/coordinate";
      };
    });
  };
}

