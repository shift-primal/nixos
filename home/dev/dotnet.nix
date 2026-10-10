{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dotnet-sdk
    omnisharp-roslyn
    fsautocomplete
    csharpier
    fantomas
    netcoredbg
  ];
}
