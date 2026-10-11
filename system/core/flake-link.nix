{ vars, ... }:

{
    # /etc/nixos -> the flake, so plain `nixos-rebuild switch` finds it and picks the
    # config named after the hostname. "L" never replaces an existing /etc/nixos, so
    # on a fresh install move the installer's directory away once first.
    systemd.tmpfiles.rules = [ "L /etc/nixos - - - - ${vars.flakeDir}" ];
}
