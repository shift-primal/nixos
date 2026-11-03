{ config, inputs, ... }:

let
    inherit (config) vars;
    hostname = "kash-homelab";
    nixos = config.flake.modules.nixos;
in
{

    flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
        modules = [ nixos.${hostname} ];
    };

    flake.modules.nixos.${hostname} = {

        imports = [
            nixos.common
            nixos.homelab
            ./_hardware-configuration.nix
        ];

        networking.hostName = hostname;

        homelab.komodo.domain = "komodo.haugestol.com";
        homelab.komodo.webhookDomain = "hooks.haugestol.com";
        homelab.immich.domain = "photos.haugestol.com";

        homelab.tunnel.id = "9533558e-052d-442c-9790-c20eb59c4b8e";

        homelab.tailnet = "tail2b3796.ts.net";

        homelab.pocketId = {
            domain = "id.haugestol.com";
            users.${vars.user.name} = {
                inherit (vars.user) fullName;
                admin = true;
            };
        };
        homelab.drive = {
            domain = "drive.haugestol.com";
            users.${vars.user.name} = "admin";
        };

        homelab.githubRunners = {
            gront-lys.url = "https://github.com/shift-primal/gront-lys-app";
            anteria.url = "https://github.com/anteria-as";
        };

        system.stateVersion = "26.05";
    };
}
