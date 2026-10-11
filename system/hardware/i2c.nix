_:

{
    # ddcutil talks to monitors over /dev/i2c-*; the user is in the i2c group (system/core/users.nix).
    hardware.i2c.enable = true;
}
