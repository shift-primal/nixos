_:

{
    flake.modules.nixos.workstation = {
        # Solaar (and its udev rules) is what the Noctalia mx-control plugin shells out to.
        programs.solaar.enable = true;
    };
}
