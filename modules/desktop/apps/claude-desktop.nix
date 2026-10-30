{ inputs, ... }:

{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        let
            claude-desktop = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;
        in
        {
            # Electron only picks the Secret Service (keyring.nix) on desktops it knows, and
            # XDG_CURRENT_DESKTOP=Hyprland is not one, so it falls back to unencrypted storage and
            # sign-ins don't persist. Wrapped in bin/ so the desktop entry (Exec=claude-desktop) gets it too.
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
