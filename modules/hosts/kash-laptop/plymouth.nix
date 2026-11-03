_:

{
    flake.modules.nixos.kash-laptop = {

        boot = {

            initrd.kernelModules = [ "i915" ];

            loader.timeout = 0;
        };
    };
}
