{
    flake.modules.nixos.docker =
        { vars, ... }:
        {
            virtualisation.docker = {
                enable = true;
                daemon.settings.live-restore = true;
            };
            users.users.${vars.user.name}.extraGroups = [ "docker" ];
        };
}
