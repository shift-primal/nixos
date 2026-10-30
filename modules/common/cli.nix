{ inputs, ... }:

{
    flake.modules.homeManager.common =
        { pkgs, ... }:
        {
            # kitty, neovim, btop and yazi are default apps, see modules/flake/vars.nix.
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
                evtest
                gocryptfs
                git-filter-repo
                unzip
                zip
                _7zz
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
