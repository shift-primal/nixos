{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        git
        git-filter-repo
        lazygit
        gh
        ripgrep
        fd
        eza
        tree
        fastfetch
        trash-cli
        curl
        wget
        openssl
        dnsutils
        jq
        yq
        sqlite
        lazysql
        unzip
        zip
        _7zz
        rbw
        bitwarden-cli
        bws
        gocryptfs
        yt-dlp
        ffmpeg
        ddcutil
        evtest
        railway
        cloudflared
        stripe-cli
    ];
}
