{
    flake.modules.nixos.gaming =
        { pkgs, ... }:
        {
            programs.steam.enable = true;

            hm.home.packages = with pkgs; [
                bolt-launcher
                lutris
                wowup-cf
            ];
        };
}
