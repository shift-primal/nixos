{ pkgs, ... }:

{
    # Creates the wireshark group (added to the user in system/core/users.nix) for capture rights.
    programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
    };
}
