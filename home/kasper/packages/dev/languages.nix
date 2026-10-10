{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python3.withPackages (ps: [ ps.debugpy ]))
    gcc
    rustc
    cargo
    nodejs
    pnpm
    sassc
    go
    dotnet-sdk

  ];
}
