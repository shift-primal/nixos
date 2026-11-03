{
    config,
    inputs,
    vars,
    ...
}:

let
    inherit (config.networking) hostName;
    stateVersion = config.system.stateVersion;
in
{
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";

        users.${vars.user.name} =
            {
                config,
                lib,
                pkgs,
                ...
            }:
            let
                link = path: config.lib.file.mkOutOfStoreSymlink "${vars.flakeDir}/dotfiles/${path}";
                dotDir = "${config.xdg.configHome}/zsh";
                dotDirRel = lib.removePrefix "${config.home.homeDirectory}/" dotDir;
                skills = lib.attrNames (
                    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./dotfiles/claude/skills)
                );
                luaVars = {
                    inherit (vars) keyboard;
                    hostname = hostName;
                    cursor = { inherit (vars.cursor) name size; };
                    apps = lib.mapAttrs (_: name: pkgs.${name}.meta.mainProgram) vars.apps;
                };
            in
            {
                home = {
                    username = vars.user.name;
                    homeDirectory = vars.user.home;
                    inherit stateVersion;
                };

                programs.home-manager.enable = true;

                nix.gc = {
                    automatic = true;
                    dates = "weekly";
                    options = "--delete-older-than 7d";
                };

                xdg.configFile =
                    lib.mapAttrs (_: path: { source = link path; }) {
                        "starship.toml" = "starship.toml";
                        "zsh/.zshrc" = "zsh/.zshrc";
                        "hypr" = "hypr";
                        "kitty" = "kitty";
                        "nvim" = "nvim";
                        "oxc" = "oxc";
                        "mise/config.toml" = "mise/config.toml";
                        "noctalia/config.toml" = "noctalia/config.toml";
                        "noctalia/host.toml" = "noctalia/hosts/${hostName}.toml";
                    }
                    // {
                        "nixos-vars/vars.lua".text = "return ${lib.generators.toLua { } luaVars}\n";
                    };

                xdg.stateFile."noctalia/settings.toml" = {
                    source = link "noctalia/settings/${hostName}.toml";
                    force = true;
                };

                home.file = {
                    ".oxfmtrc.json".source = link "oxc/oxfmtrc.json";
                    "${dotDirRel}/.zshrc".enable = lib.mkForce false;
                    "${dotDirRel}/hm-init.zsh".text = config.programs.zsh.initContent;
                }
                // lib.listToAttrs (
                    map (
                        name: lib.nameValuePair ".claude/skills/${name}" { source = link "claude/skills/${name}"; }
                    ) skills
                );

                home.activation.miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
                    PATH="${
                        lib.makeBinPath (
                            with pkgs;
                            [
                                git
                                curl
                                gnutar
                                gzip
                                xz
                            ]
                        )
                    }:$PATH" run ${lib.getExe pkgs.mise} install --yes || true
                    run ${lib.getExe pkgs.mise} reshim || true
                '';

                programs.git = {
                    enable = true;
                    ignores = [
                        ".direnv/"
                        "result"
                        "result-*"
                    ];
                };

                programs = {
                    direnv = {
                        enable = true;
                        config.global.hide_env_diff = true;
                    };
                    zoxide.enable = true;
                    starship.enable = true;
                    fzf.enable = true;
                };

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

                    sessionVariables = {
                        SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
                        PNPM_HOME = "$HOME/.local/share/pnpm";
                        _ZO_DOCTOR = "0";
                        npm_config_manage_package_manager_versions = "false";
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

                    initContent = lib.mkOrder 560 ''
                        path=(
                          "$HOME/.local/bin"
                          "$PNPM_HOME/bin"
                          "$HOME/.cargo/bin"
                          $path
                        )
                    '';
                };
            };
    };
}
