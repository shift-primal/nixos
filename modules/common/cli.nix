_:

{

    flake.modules.homeManager.common =
        { pkgs, ... }:
        {

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
