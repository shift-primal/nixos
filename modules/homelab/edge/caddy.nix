_:

{

    flake.modules.nixos.homelab.services.caddy = {
        enable = true;

        globalConfig = ''
            auto_https off
            default_bind 127.0.0.1 [::1]
            servers {
                trusted_proxies static 127.0.0.1/32 ::1/128
                client_ip_headers Cf-Connecting-Ip X-Forwarded-For
            }
        '';
    };
}
