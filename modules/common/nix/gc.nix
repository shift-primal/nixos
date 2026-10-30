_:

{
    flake.modules.nixos.common = {
        # Keeps a week of generations to roll back to; anything older is freed.
        nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
        };
    };

    # The root job above does not see Home Manager's generations, which live in the user's profile.
    flake.modules.homeManager.common = {
        nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
        };
    };
}
