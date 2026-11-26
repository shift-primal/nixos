{
    flake.modules.nixos.ssh =
        { lib, vars, ... }:
        {
            services.openssh = {
                enable = true;
                openFirewall = false;
                settings = {
                    PasswordAuthentication = false;
                    KbdInteractiveAuthentication = false;
                    PermitRootLogin = "no";
                };
            };

            programs.ssh = {
                systemd-ssh-proxy.enable = false;
                extraConfig = lib.concatMapStrings (host: ''
                    Host ${lib.removePrefix "kash-" host}
                        HostName ${host}
                '') vars.hosts;
            };
        };
}
