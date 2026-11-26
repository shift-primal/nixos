{
    flake.modules.nixos.config-tools =
        { pkgs, link, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    nixfmt-wrapped
                    treefmt
                    nil
                    statix
                    lua-language-server
                    stylua
                    tombi
                    sops
                    age
                ];

                xdg.configFile = {
                    "tombi".source = link "tombi";
                    "stylua".source = link "stylua";
                };
            };
        };
}
