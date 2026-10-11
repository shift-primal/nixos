{ pkgs, ... }:

{
    services.printing = {
        enable = true;
        drivers = [ pkgs.hplip ];
    };

    # Finds network printers over mDNS.
    services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
    };
}
