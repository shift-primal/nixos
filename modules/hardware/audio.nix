{
    flake.modules.nixos.audio = {
        security.rtkit.enable = true;

        services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
        };

        hm.services.easyeffects = {
            enable = true;
            preset.input = "Kasper";
        };
    };
}
