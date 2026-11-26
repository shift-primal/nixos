{
    flake.modules.nixos.web =
        { pkgs, link, ... }:
        {
            hm = {
                home.packages = with pkgs; [
                    nodejs
                    pnpm
                    typescript
                    oxlint
                    oxfmt
                    biome
                    prettier
                ];

                programs.zsh.sessionVariables = {
                    PNPM_HOME = "$HOME/.local/share/pnpm";
                    npm_config_manage_package_manager_versions = "false";
                };

                xdg.configFile."oxc".source = link "oxc";
                home.file.".oxfmtrc.json".source = link "oxc/oxfmtrc.json";
            };
        };
}
