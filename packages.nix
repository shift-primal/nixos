{
    inputs,
    lib,
    pkgs,
    vars,
    ...
}:

let
    editor = pkgs.${vars.apps.editor};
in
{
    environment.variables = {
        EDITOR = editor.meta.mainProgram;
        VISUAL = editor.meta.mainProgram;
    };

    environment.systemPackages =
        map (name: pkgs.${name}) (lib.attrValues vars.apps)
        ++ [ inputs.grimoire.packages.${pkgs.stdenv.hostPlatform.system}.default ]
        ++ (with pkgs; [
            bitwarden-desktop
            filezilla
            vlc
            mpv
            inkscape
            (onlyoffice-desktopeditors.override { extraFontPackages = [ corefonts ]; })
            libreoffice
            bolt-launcher
            lutris

            claude-code

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
            yq
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

            nixfmt-wrapped
            treefmt
            nil
            statix
            lua-language-server
            stylua
            tombi
            sops
            age
            oxfmt
            mise
            tree-sitter
            gcc
            wowup-cf
        ]);
}
