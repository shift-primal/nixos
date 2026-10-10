{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  # Hyprland autostart already execs `noctalia`. Leave the user service off
  # so the shell is not started twice.
  programs.noctalia.enable = true;
}
