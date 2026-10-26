_:

{
    # Web apps moved over from Coolify on the Hetzner VPS (modules/server/komodo/apps.nix).
    # Ports count up from 3001; containers listen on 3000 unless containerPort says otherwise.
    # Secret values go in secrets/hosts/kash-homelab.yaml under apps/<app>/<key>.
    flake.modules.nixos.kash-homelab.homelab.apps = {
        pokemon = {
            domain = "pokemon.haugestol.com";
            port = 3001;
            repo = "shift-primal/pdex_26";
        };

        quiz = {
            domain = "quiz.haugestol.com";
            port = 3002;
            repo = "shift-primal/bfq";
            secrets = [ "DATABASE_URL" ];
            # The real questions are gitignored so the answers stay out of the public repo.
            buildFiles."src/config/questions.data.ts" = "questions";
        };

        spot = {
            domain = "spot.haugestol.com";
            port = 3003;
            repo = "shift-primal/spot";
            # SQLite (DB_PATH). It had no volume on Coolify, so every redeploy there started empty.
            volumes.spot-data = "/app/server/data";
        };

        haugestol = {
            domain = "haugestol.com";
            port = 3004;
            repo = "shift-primal/haugestol_homepage";
            secrets = [
                "GITHUB_TOKEN"
                "RESEND_API_KEY"
            ];
        };

        # wastescope. Its compose file runs migrations and reseeds the demo accounts on each deploy.
        ws = {
            domain = "ws.haugestol.com";
            port = 3005;
            repo = "shift-primal/ws";
            compose = {
                files = [ "docker-compose.prod.yml" ];
                # Nightly pg_dumpall (backup.nix).
                override.services.db.labels."homelab.backup" = "postgres";
            };
            environment.BETTER_AUTH_URL = "https://ws.haugestol.com";
            secrets = [
                "POSTGRES_PASSWORD"
                "BETTER_AUTH_SECRET"
            ];
        };
    };
}
