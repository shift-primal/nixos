{ inputs, ... }:

{
    # CLI tools only the desktops need. The ones every host gets are in modules/common/cli.nix.
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
                # `cloudflared tunnel route dns` for homelab hostnames (modules/homelab/edge/cloudflared.nix).
                cloudflared
                cutover
                stripe-cli

                grok-cli
                skills
                inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.stable

                inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
                inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide
                inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
            ];
        };
}
