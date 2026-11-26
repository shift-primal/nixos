{
    flake.modules.nixos.ai =
        {
            lib,
            pkgs,
            inputs,
            link,
            ...
        }:
        let
            claude-desktop = pkgs.symlinkJoin {
                name = "claude-desktop";
                paths = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                    wrapProgram $out/bin/claude-desktop --add-flags "--password-store=gnome-libsecret"
                '';
            };
            skillDirs = lib.attrNames (
                lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../dotfiles/claude/skills)
            );
        in
        {
            hm = {
                home.packages = [
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

                home.file = lib.listToAttrs (
                    map (
                        name: lib.nameValuePair ".claude/skills/${name}" { source = link "claude/skills/${name}"; }
                    ) skillDirs
                );
            };
        };
}
