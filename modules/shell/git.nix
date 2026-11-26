{
    flake.modules.nixos.git =
        { pkgs, ... }:
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
                };

                home.packages = with pkgs; [
                    git-filter-repo
                    lazygit
                    gh
                ];
            };
        };
}
