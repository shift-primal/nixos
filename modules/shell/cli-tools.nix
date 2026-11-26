{
    flake.modules.nixos.cli-tools =
        { pkgs, link, ... }:
        {
            environment.systemPackages = with pkgs; [
                curl
                wget
            ];

            hm = {
                home.packages = with pkgs; [
                    ripgrep
                    fd
                    eza
                    tree
                    fastfetch
                    trash-cli
                    openssl
                    dnsutils
                    jq
                    yq
                    sqlite
                    lazysql
                    unzip
                    zip
                    _7zz
                    gocryptfs
                    yt-dlp
                    ffmpeg
                    evtest
                ];

                xdg.configFile."btop/btop.conf".source = link "btop/btop.conf";
            };
        };
}
