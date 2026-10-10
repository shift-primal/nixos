_:

{
  # Hyprland itself is configured live from dotfiles/hypr.
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    gpu-screen-recorder.enable = true;
    dconf.enable = true;
  };

  # Used by the Noctalia shell for battery and power profile widgets.
  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
  };
}
