_:

{
    # Push alerts to the phone through ntfy.sh. `ntfy-alert <title> <message>` (as root) sends one,
    # for smartd (smartd.nix) and anything else that needs to shout.
    flake.modules.nixos.homelab =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            ntfy-alert = pkgs.writeShellApplication {
                name = "ntfy-alert";
                runtimeInputs = with pkgs; [ curl ];
                text = ''
                    curl -fsS -m 10 --retry 5 -o /dev/null \
                        -H "Title: $1" -H "Priority: high" -H "Tags: warning" \
                        --data-binary "$2" "$(cat ${config.sops.secrets."ntfy/url".path})"
                '';
            };
        in
        {
            options.homelab.ntfy-alert = lib.mkOption {
                type = lib.types.package;
                default = ntfy-alert;
                readOnly = true;
                description = "The ntfy-alert command, for services that alert.";
            };

            config = {
                # https://ntfy.sh/<topic>. Anyone who knows the topic can read and post to it, so pick
                # a long random one (`openssl rand -hex 16`) and subscribe to it in the ntfy app.
                sops.secrets."ntfy/url" = { };

                environment.systemPackages = [ ntfy-alert ];
            };
        };
}
