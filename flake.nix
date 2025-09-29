{
  description = "Fleet Toolkit (portable tools for mixed-distro hosts)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f:
      builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);
  in {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # A single meta-package composed of common tools
        toolkit = pkgs.buildEnv {
          name = "fleet-toolkit";
          paths = with pkgs; [
            coreutils gawk gnused findutils
            curl wget rsync
            jq yq fastfetch
            iproute2 iptables nftables
            nmap masscan
            htop tmux ripgrep fd
            socat netcat tcpdump
            unzip zip xz
          ];
        };

        default = self.packages.${system}.toolkit;
      }
    );
  }
}

