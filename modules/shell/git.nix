{
    flake.modules.nixos.git =
        { lib, pkgs, ... }:
        {
            environment.systemPackages = [ pkgs.git ];

            hm = {
                programs.git = {
                    enable = true;
                    ignores = [
                        ".direnv/"
                        "result"
                        "result-*"
                        "**/.claude/settings.local.json"
                    ];
                    settings.credential = lib.genAttrs [ "https://github.com" "https://gist.github.com" ] (_: {
                        helper = [
                            ""
                            "!${lib.getExe pkgs.gh} auth git-credential"
                        ];
                    });
                };

                home.packages = with pkgs; [
                    git-filter-repo
                    lazygit
                    gh
                ];
            };
        };
}
