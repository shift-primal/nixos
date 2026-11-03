{
    lib,
    pkgs,
    inputs,
    vars,
    ...
}:

let
    system = pkgs.stdenv.hostPlatform.system;
    editor = pkgs.${vars.apps.editor};
in
{
    environment.variables = {
        EDITOR = editor.meta.mainProgram;
        VISUAL = editor.meta.mainProgram;
    };

    environment.systemPackages =
        map (name: pkgs.${name}) (lib.attrValues vars.apps)
        ++ (with pkgs; [
            bitwarden-desktop
            obsidian
            filezilla
            vlc
            mpv
            inkscape
            (onlyoffice-desktopeditors.override { extraFontPackages = [ corefonts ]; })
            libreoffice

            wl-clipboard
            cliphist
            wl-clip-persist
            v4l-utils
            slurp
            grim
            satty
            hyprpicker
            imagemagick
            wev
            (tesseract.override {
                enableLanguages = [
                    "eng"
                    "nor"
                ];
            })
            zbar
            gifski

            git
            wget
            ripgrep
            fd
            eza
            fastfetch
            lazygit
            gh
            trash-cli
            sqlite
            jq
            curl
            openssl
            tree
            dnsutils
            unzip
            zip
            _7zz
            lazysql
            rbw
            bitwarden-cli
            bws
            obsidian-headless
            libnotify
            yt-dlp
            ffmpeg
            ddcutil
            evtest
            gocryptfs
            git-filter-repo
            gowall
            railway
            cloudflared
            stripe-cli
            skills
            inputs.nix-claude-code.packages.${system}.stable
            inputs.ai-usagebar.packages.${system}.default

            nixfmt-wrapped
            treefmt
            nil
            statix
            lua-language-server
            stylua
            shfmt
            tombi
            marksman
            oxfmt
            mise
            dockerfile-language-server
            docker-compose-language-service
            hadolint
            tree-sitter
            gcc
        ]);
}
