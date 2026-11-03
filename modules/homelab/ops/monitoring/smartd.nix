_:

{

    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            notify = pkgs.writeShellScript "smartd-ntfy" ''
                exec ${lib.getExe config.homelab.ntfy-alert} "$SMARTD_SUBJECT" "$SMARTD_FULLMESSAGE"
            '';
        in
        {
            services.smartd = {
                enable = true;

                notifications.wall.enable = false;

                defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../7/05) -W 4,45,55 -n standby,24,q -m <nomailer> -M exec ${notify}";
            };

            environment.systemPackages = with pkgs; [ smartmontools ];
        };
}
