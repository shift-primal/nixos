_:

{
    # GPU drivers are per machine and imported from hosts/<hostname>/.
    imports = [
        ./audio.nix
        ./bluetooth.nix
        ./i2c.nix
        ./logitech.nix
    ];
}
