_:

{
    flake.modules.nixos.base = {
        # Firmware updates from LVFS: `fwupdmgr refresh && fwupdmgr update`.
        services.fwupd.enable = true;
    };
}
