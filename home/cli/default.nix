{ inputs, pkgs, ... }:

{
    # kitty, neovim, btop and yazi are default apps, see vars.nix.
    home.packages = with pkgs; [
        ripgrep
        fd
        eza
        fastfetch
        lazygit
        gh
        trash-cli
        sqlite
        lazysql
        rbw
        bitwarden-cli
        bws
        obsidian-headless
        jq
        curl
        openssl
        tree
        libnotify
        dnsutils
        yt-dlp
        ffmpeg
        ddcutil
        gocryptfs
        git-filter-repo
        unzip
        zip
        _7zz
        gowall

        railway
        stripe-cli

        grok-cli
        skills
        inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.stable
    ];
}
