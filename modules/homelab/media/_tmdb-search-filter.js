// Preloaded into the TMDB addon (tmdb-addon.nix) through NODE_OPTIONS. TMDB's search lists every
// title that matches, down to unreleased shorts nobody has rated, and the addon adds the films and
// series of any person whose name matches. Infuse sorts what it gets by name, so all of that sat
// between the titles we were looking for.
const { MovieDb } = require(require.resolve("moviedb-promise", { paths: ["/app"] }));

const minVotes = Number(process.env.SEARCH_MIN_VOTES || 25);

for (const name of ["searchMovie", "searchTv"]) {
    const search = MovieDb.prototype[name];
    MovieDb.prototype[name] = async function (...args) {
        const res = await search.apply(this, args);
        const byPopularity = [...(res.results || [])].sort((a, b) => b.popularity - a.popularity);
        const known = byPopularity.filter((t) => t.vote_count >= minVotes);
        // A search for something new or obscure still finds its best few matches.
        return { ...res, results: known.length > 0 ? known : byPopularity.slice(0, 5) };
    };
}

// The addon looks a person up for every search and adds all their credits.
MovieDb.prototype.searchPerson = async () => ({ page: 1, results: [], total_pages: 0, total_results: 0 });

console.log(`search filter: at least ${minVotes} votes, no person credits`);
