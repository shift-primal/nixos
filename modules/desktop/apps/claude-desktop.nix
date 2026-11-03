{ inputs, ... }:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        let
            claude-desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
        in
        {

            home.packages = [
                (pkgs.symlinkJoin {
                    name = "claude-desktop";
                    paths = [ claude-desktop ];
                    nativeBuildInputs = [ pkgs.makeWrapper ];
                    postBuild = ''
                        wrapProgram $out/bin/claude-desktop --add-flags "--password-store=gnome-libsecret"
                    '';
                })
            ];
        };
}
