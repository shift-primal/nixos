_:

# One file per language: toolchain plus the LSP servers, formatters, etc.
# Mason is disabled, so Nix installs every binary.
{
    imports = [
        ./c.nix
        ./docker.nix
        ./dotnet.nix
        ./go.nix
        ./lua.nix
        ./markdown.nix
        ./neovim.nix
        ./nix.nix
        ./python.nix
        ./rust.nix
        ./shell.nix
        ./toml.nix
        ./web.nix
    ];
}
