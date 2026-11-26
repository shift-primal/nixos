{
    flake.modules.nixos.jetbrains =
        { pkgs, link, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    jetbrains.rider
                    jetbrains.webstorm
                ];

                xdg.configFile."ideavim".source = link "ideavim";
            };
        };
}
