{ pkgs, vars, ... }:

let
    dotnet = pkgs.dotnetCorePackages.combinePackages (
        with pkgs.dotnetCorePackages;
        [
            sdk_8_0
            sdk_9_0
            sdk_10_0
        ]
    );
in
{
    virtualisation.docker = {
        enable = true;
        daemon.settings.live-restore = true;
    };

    programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
    };

    users.users.${vars.user.name}.extraGroups = [
        "docker"
        "wireshark"
    ];
    environment = {

        systemPackages = [
            dotnet
        ]
        ++ (with pkgs; [
            jetbrains.rider
            csharpier
            fantomas
            omnisharp-roslyn
            fsautocomplete
        ]);
        sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";

        extraInit = ''
            export PATH="$HOME/.local/share/mise/shims:$PATH"
        '';
    };
}
