{
    flake.modules.homeManager.common = {
        programs.git = {
            enable = true;
            ignores = [
                ".direnv/"
                "result"
                "result-*"
            ];
        };
    };
}
