{ pkgs, ... }:

{
    home.packages = with pkgs; [
        # One dotnet root holding every SDK, so global.json can pick any of them.
        (dotnetCorePackages.combinePackages [
            dotnetCorePackages.sdk_8_0
            dotnetCorePackages.sdk_9_0
            dotnetCorePackages.sdk_10_0
        ])
        omnisharp-roslyn
        fsautocomplete
        csharpier
        fantomas
        netcoredbg
    ];
}
