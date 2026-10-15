{ inputs, pkgs, ... }:

{
    # The terminal, editor, btop and yazi are default apps, see vars.nix.
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
        # Noctalia plugins: bitwarden talks to `bw serve`, claude-cockpit uses jq and curl.
        bitwarden-cli
        bws # Bitwarden Secrets Manager CLI
        jq
        curl
        openssl
        tree
        libnotify # notify-send, used by Noctalia plugins and its session menu
        dnsutils # dig, nslookup
        yt-dlp
        ddcutil # external monitor brightness, needs hardware.i2c (system/hardware/i2c.nix)
        gocryptfs
        git-filter-repo
        unzip
        zip
        _7zz
        gowall

        railway
        stripe-cli

        grok-cli
        skills # skills.sh CLI for third-party skills; own skills are linked by home/claude-skills.nix
        inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.stable
    ];
}
