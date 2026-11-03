_:

{
    # Web apps moved over from Coolify on the Hetzner VPS (modules/homelab/apps/komodo/apps.nix).
    # Ports count up from 3001; containers listen on 3000 unless containerPort says otherwise.
    # Secret values go in secrets/hosts/kash-homelab.yaml under apps/<app>/<key>.
    flake.modules.nixos.kash-homelab.homelab.apps = {
        pokemon = {
            domain = "pokemon.haugestol.com";
            port = 3001;
            repo = "shift-primal/pdex_26";
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
                oneShot = [
                    "migrate"
                    "seed"
                ];
                # Nightly pg_dumpall (backup.nix).
                override.services.db.labels."homelab.backup" = "postgres";
            };
            environment.BETTER_AUTH_URL = "https://ws.haugestol.com";
            secrets = [
                "POSTGRES_PASSWORD"
                "BETTER_AUTH_SECRET"
            ];
        };

        # Images come from klyndre's own GitHub Actions (ghcr, public), so this is the whole compose
        # file. Its repo's docker-compose.yml is Coolify-flavoured (SERVICE_* values, exclude_from_hc).
        klyndre = {
            domain = "klyndre.haugestol.com";
            port = 3006;
            compose = {
                service = "web";
                oneShot = [ "migrate" ];
                override =
                    let
                        databaseUrl = "postgres://klyndre:\${POSTGRES_PASSWORD}@db:5432/klyndre";
                        afterMigrate.migrate.condition = "service_completed_successfully";
                    in
                    {
                        services = {
                            db = {
                                image = "postgres:18";
                                restart = "unless-stopped";
                                environment = {
                                    POSTGRES_USER = "klyndre";
                                    POSTGRES_PASSWORD = "\${POSTGRES_PASSWORD}";
                                    POSTGRES_DB = "klyndre";
                                };
                                volumes = [ "postgres-data:/var/lib/postgresql" ];
                                healthcheck = {
                                    test = [
                                        "CMD-SHELL"
                                        "pg_isready -U klyndre -d klyndre"
                                    ];
                                    interval = "5s";
                                    timeout = "5s";
                                    retries = 10;
                                };
                                # Nightly pg_dumpall (backup.nix).
                                labels."homelab.backup" = "postgres";
                            };
                            migrate = {
                                image = "ghcr.io/shift-primal/klyndre-migrate:latest";
                                restart = "no";
                                depends_on.db.condition = "service_healthy";
                                environment.DATABASE_URL = databaseUrl;
                            };
                            # Only one bot may be logged in to Discord: stop the old one before deploying.
                            # No YOUTUBE_PROXY: on a home connection the bot streams YouTube directly.
                            bot = {
                                image = "ghcr.io/shift-primal/klyndre-bot:latest";
                                restart = "unless-stopped";
                                depends_on = afterMigrate;
                                environment = {
                                    DATABASE_URL = databaseUrl;
                                    DISCORD_TOKEN = "\${DISCORD_TOKEN}";
                                    DISCORD_CLIENT_ID = "\${DISCORD_CLIENT_ID}";
                                    XAI_API_KEY = "\${XAI_API_KEY}";
                                    DP_SPOTIFY_CLIENT_ID = "\${DP_SPOTIFY_CLIENT_ID}";
                                    DP_SPOTIFY_CLIENT_SECRET = "\${DP_SPOTIFY_CLIENT_SECRET}";
                                };
                            };
                            web = {
                                image = "ghcr.io/shift-primal/klyndre-web:latest";
                                restart = "unless-stopped";
                                depends_on = afterMigrate;
                                environment = {
                                    DATABASE_URL = databaseUrl;
                                    BETTER_AUTH_URL = "https://klyndre.haugestol.com";
                                    BETTER_AUTH_SECRET = "\${BETTER_AUTH_SECRET}";
                                };
                            };
                        };
                        volumes.postgres-data = { };
                    };
            };
            secrets = [
                "POSTGRES_PASSWORD"
                "BETTER_AUTH_SECRET"
                "DISCORD_TOKEN"
                "DISCORD_CLIENT_ID"
                "XAI_API_KEY"
                "DP_SPOTIFY_CLIENT_ID"
                "DP_SPOTIFY_CLIENT_SECRET"
            ];
        };

        # The old dashboard, kept at homehub.local until Homepage (homelab/apps/homepage.nix), which
        # took over hub.local and http://kash-homelab, has proven itself. API keys for the apps it
        # reads go in `secrets`, so they stay server-side.
        homehub = {
            port = 3009;
            repo = "shift-primal/homehub";
            localNames = [ "homehub.local" ];
            # Status checks hit every service on 127.0.0.1 (src/server/services.ts in homehub).
            hostNetwork = true;
            environment = {
                APP_ENV = "prod";
                # Read-only Beszel account, made by beszel-configure (homelab/ops/monitoring/beszel.nix).
                BESZEL_URL = "http://127.0.0.1:8090";
                BESZEL_EMAIL = "homehub@homehub.local";
            };
            secrets = [ "BESZEL_PASSWORD" ];
        };
    };
}
