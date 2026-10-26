_:

{
    # Web apps moved over from Coolify on the Hetzner VPS (modules/server/komodo/apps.nix).
    # Ports count up from 3001; containers listen on 3000 unless containerPort says otherwise.
    flake.modules.nixos.kash-homelab.homelab.apps = {
        pokemon = {
            domain = "pokemon.haugestol.com";
            port = 3001;
            repo = "shift-primal/pdex_26";
        };
    };
}
