{
    flake.modules.nixos.neovim =
        { pkgs, link, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    tree-sitter
                    gcc
                ];

                xdg.configFile."nvim".source = link "nvim";
            };
        };
}
