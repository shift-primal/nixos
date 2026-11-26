{
    flake.modules.nixos.zsh =
        { pkgs, vars, ... }:
        {
            programs.zsh = {
                enable = true;
                enableGlobalCompInit = false;
                promptInit = "";
            };
            users.users.${vars.user.name}.shell = pkgs.zsh;

            hm =
                { config, lib, ... }:
                let
                    dotDir = "${config.xdg.configHome}/zsh";
                in
                {
                    programs.zsh = {
                        enable = true;
                        inherit dotDir;

                        defaultKeymap = "emacs";
                        enableCompletion = true;

                        autosuggestion.enable = true;
                        syntaxHighlighting.enable = true;

                        history = {
                            size = 10000;
                            extended = true;
                            path = "${dotDir}/.zsh_history";
                        };

                        localVariables = {
                            DISABLE_AUTO_TITLE = "true";
                            COMPLETION_WAITING_DOTS = "true";
                        };

                        oh-my-zsh = {
                            enable = true;
                            plugins = [
                                "git"
                                "aliases"
                                "colorize"
                                "eza"
                            ];
                            extraConfig = ''
                                ZSH_DISABLE_COMPFIX=true
                                zstyle ':omz:update' mode reminder
                            '';
                        };

                        initContent = lib.mkMerge [
                            (lib.mkOrder 560 ''
                                path=(
                                  "$HOME/.local/bin"
                                  "$PNPM_HOME/bin"
                                  "$HOME/.cargo/bin"
                                  $path
                                )
                            '')
                            (lib.mkAfter ''
                                rc="${vars.flakeDir}/dotfiles/zsh/rc.zsh"
                                [[ -r $rc ]] && source "$rc"
                                unset rc
                            '')
                        ];
                    };
                };
        };
}
