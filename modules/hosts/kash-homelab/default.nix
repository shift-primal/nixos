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
        # Secrets for komodo, cloudflared and backup live in secrets/hosts/kash-homelab.yaml (sops).
        imports = [
            nixos.base
            nixos.komodo
            nixos.caddy
            nixos.cloudflared
            nixos.backup
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        homelab.komodo.domain = "komodo.haugestol.com";
        homelab.komodo.webhookDomain = "hooks.haugestol.com";
        # The "homelab" tunnel (cloudflared.nix). Route a hostname to it with
        #   cloudflared tunnel route dns homelab <host>
        homelab.tunnel.id = "9533558e-052d-442c-9790-c20eb59c4b8e";

        # Release this machine was first installed with. Do not bump on upgrades.
        # Must match system.stateVersion in the installer's /etc/nixos/configuration.nix.
        system.stateVersion = "26.05";
    };
}
