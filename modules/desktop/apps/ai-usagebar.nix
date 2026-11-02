{ inputs, ... }:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            # The Noctalia plugin felipeartur/ai-usagebar (enabled in dotfiles/noctalia/settings) runs
            # `ai-usagebar usage --json` by name, so it has to be on PATH. Also gives ai-usagebar-tui.
            home.packages = [
                inputs.ai-usagebar.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
        };
}
