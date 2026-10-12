_:

{
    # Lets prebuilt generic-Linux binaries (npm packages like @biomejs/cli-linux-x64) run without
    # patching; they look for a loader at /lib64/ld-linux-x86-64.so.2, which NixOS lacks.
    programs.nix-ld.enable = true;
}
