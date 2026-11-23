{ inputs, pkgs, ... }:

let
    claude-desktop = pkgs.symlinkJoin {
        name = "claude-desktop";
        paths = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/claude-desktop --add-flags "--password-store=gnome-libsecret"
        '';
    };
in
{
    environment.systemPackages = [
        claude-desktop
    ]
    ++ (with pkgs; [
        claude-code
        opencode
        opencode-desktop
        google-antigravity
        google-antigravity-cli
        skills
    ]);
}
