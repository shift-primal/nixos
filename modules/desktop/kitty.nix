{
    flake.modules.nixos.kitty =
        { pkgs, link, ... }:
        {
            environment.systemPackages = [ pkgs.kitty.terminfo ];

            hm.xdg.configFile."kitty".source = link "kitty";
        };
}
