_:

{
    # Watches every SATA disk (the SSD and the 4 TB HDD) and pushes a SMART warning, failing
    # self-test or overheating through ntfy-alert (ntfy.nix). Beszel (beszel.nix) graphs the same
    # SMART data but can't schedule self-tests, so smartd stays.
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
                # Nobody is logged in to read wall messages.
                notifications.wall.enable = false;
                # -a: health, attributes, error and self-test logs. -o/-S: offline data collection and
                # attribute autosave. -s: short self-test daily at 02:00, long one Sundays at 05:00 (after
                # the 03:00 backup). -W: log a 4 °C jump and 45 °C, alert at 55 °C. -n: skip a check
                # while the HDD is spun down, but not more than 24 in a row. -M exec: alert through ntfy.
                defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../7/05) -W 4,45,55 -n standby,24,q -m <nomailer> -M exec ${notify}";
            };

            # `smartctl -a /dev/sdX` to read a disk by hand; the smartd module doesn't install it.
            environment.systemPackages = with pkgs; [ smartmontools ];
        };
}
