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
        install-toolkit = pkgs.buildEnv {
          name = "fleet-toolkit";
          paths = with pkgs; [
            coreutils gawk gnused findutils curl wget rsync git
            jq yq fastfetch iproute2 iptables nftables
            nmap masscan htop tmux ripgrep fd socat netcat tcpdump
            unzip zip xz
          ];
        };

        coordinate = pkgs.buildGoModule {
          pname = "coordinate";
          version = "1.0.0";
          src = pkgs.lib.cleanSource ./coordinate-root;  # <-- lives in this repo
          go = pkgs.go_1_25;
          postPatch = ''find . -type d -name vendor -prune -exec rm -rf {} +'';
          vendorHash = "sha256-xNWQNH+rP6YjEM/tU7y08ccRdYKkmGSZ2/b34bhrfCU="; # your 'got:' hash
          # subPackages = [ "cmd/coordinate" ];
        };

        default = self.packages.${system}.install-toolkit;
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

