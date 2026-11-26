{
    flake.modules.nixos.cloud =
        { pkgs, ... }:
        {
            hm.home.packages = with pkgs; [
                railway
                cloudflared
                stripe-cli
            ];
        };
}
