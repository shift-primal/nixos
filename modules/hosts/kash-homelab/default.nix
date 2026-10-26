{ config, inputs, ... }:

let
    hostname = "kash-homelab";
    nixos = config.flake.modules.nixos;
in
{
    # Named after the hostname, so `nixos-rebuild switch --flake ~/nixos` picks it.
    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    # HP ProDesk 400 G3 SFF. The other files in this folder (boot, data) add to this module too.
    flake.modules.nixos.${hostname} = {
        # _hardware-configuration.nix is generated on the ProDesk itself:
        #   nixos-generate-config --show-hardware-config > _hardware-configuration.nix
        # Secrets for komodo and cloudflared live in secrets/hosts/kash-homelab.yaml (sops).
        imports = [
            nixos.base
            nixos.komodo
            nixos.caddy
            nixos.cloudflared
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        homelab.komodo.domain = "komodo.haugestol.com";
        # Placeholder until the tunnel exists: `cloudflared tunnel create homelab` prints the UUID.
        homelab.tunnel.id = "00000000-0000-0000-0000-000000000000";

        # Release this machine was first installed with. Do not bump on upgrades.
        # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
        system.stateVersion = "26.05";
    };
}
