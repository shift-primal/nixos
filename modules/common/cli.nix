_:

{
    # CLI tools for every host, the homelab included. Desktop-only tools are in
    # modules/desktop/dev/cli.nix.
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
                jq
                curl
                openssl
                tree
                dnsutils
                unzip
                zip
                _7zz
            ];
        };
}
