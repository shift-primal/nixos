_:

{

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

                override.services.db.labels."homelab.backup" = "postgres";
            };
            environment.BETTER_AUTH_URL = "https://ws.haugestol.com";
            secrets = [
                "POSTGRES_PASSWORD"
                "BETTER_AUTH_SECRET"
            ];
        };

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

                                labels."homelab.backup" = "postgres";
                            };
                            migrate = {
                                image = "ghcr.io/shift-primal/klyndre-migrate:latest";
                                restart = "no";
                                depends_on.db.condition = "service_healthy";
                                environment.DATABASE_URL = databaseUrl;
                            };

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
    };
}
