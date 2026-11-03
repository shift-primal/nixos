{ inputs, ... }:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
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
                inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.stable
            ];
        };
}
