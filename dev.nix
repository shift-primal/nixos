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

            nodejs
            pnpm
            typescript
            oxlint
            biome
            prettier

            python3
            uv
            ruff
            sqlfluff

            go
            gopls

            rustc
            cargo
            rust-analyzer
            clippy
            rustfmt

            clang-tools

            hadolint
            shfmt
            markdownlint-cli2
        ]);
        sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";
    };
}
