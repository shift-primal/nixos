{
    flake.modules.nixos.wireshark =
        { pkgs, vars, ... }:
        {
            programs.wireshark = {
                enable = true;
                package = pkgs.wireshark;
            };
            users.users.${vars.user.name}.extraGroups = [ "wireshark" ];
        };
}
