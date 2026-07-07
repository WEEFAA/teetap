# teetap examples

Recipes and walkthroughs for querying the teetap aggregate. Everything
here composes from `grep`, `sed`, `awk`, and `tail` on plain files —
optional detail; SKILL.md alone is enough to work.

## Query recipes

```sh
DIR=$(teetap path)

grep -h "<request-id>" "$DIR"/*.log            # one identifier across ALL sources
grep -n  "ERROR\|error" "$DIR"/dev.log         # errors with line numbers
grep -c  "timeout" "$DIR"/pm2-*.log            # count per worker
grep -A3 -B3 "stack trace" "$DIR"/dev.log      # context window around a hit
grep -v  "healthcheck" "$DIR"/dev.log          # drop noise
sed -n '/13:18:00/,/13:18:30/p' "$DIR"/dev.log # time-range slice
sed -n '100,160p' "$DIR"/dev.log               # line-range slice around a grep -n hit
tail -200 "$DIR"/dev.log                       # recent activity
```

Aggregate like a log store's "group by":

```sh
grep -oh "gateway:[A-Z-]*" "$DIR"/*.log | sort | uniq -c | sort -rn
grep ERROR "$DIR"/dev.log | cut -d' ' -f1 | uniq -c     # errors per timestamp prefix
```

## Walkthrough: debug a failing request

```sh
DIR=$(teetap path)
teetap status                                  # anything fresh?
grep -h "<request-id>" "$DIR"/*.log            # which sources saw it?
grep -n "<request-id>" "$DIR"/dev.log          # note the line numbers
sed -n '1180,1240p' "$DIR"/dev.log             # read around the failure
```

The request may span sources: the API server log (`dev.log`) shows the
request arriving; a worker log (`pm2-*.log`) shows the job it queued.
Same identifier, one `grep -h` across both.

## Walkthrough: what changed since the last restart?

```sh
tail -n "+$(grep -n 'teetap session .* start' "$DIR"/dev.log | tail -1 | cut -d: -f1)" "$DIR"/dev.log
```

Then compare with the previous session if the developer used `--rotate`:

```sh
grep -c "ERROR" "$DIR"/dev.prev.log "$DIR"/dev.log     # error count, before vs after
```

## Walkthrough: machine-wide view (everything the developer runs)

```sh
teetap list                                    # every tapped project, freshest first
ROOT=${TEETAP_DIR:-$HOME/.local/state/teetap}
tail -f "$ROOT"/*/*.log                        # follow everything live
grep -l "OOM" "$ROOT"/*/*.log                  # which project hit it?
```

## Walkthrough: the logs live in another project

You are in a worktree with no tap, but the developer says the server is
running. Find it, recommend, ask:

```sh
teetap list
# PROJECT              PATH                              SOURCES  AGE_S
# PMS2.0_PH-a3f9c1     /Users/dev/PMS2.0_PH              3        4
# teetap-99be01        /Users/dev/teetap                 1        86400
```

`PMS2.0_PH-a3f9c1` is the sibling checkout and was written 4s ago — the
likely candidate. Ask the user, recommendation first; on confirmation:

```sh
DIR="${TEETAP_DIR:-$HOME/.local/state/teetap}/PMS2.0_PH-a3f9c1"
```

## Taps to suggest to the developer

They run these, not you — any runtime, any producer:

```sh
teetap run dev -- npm run dev
teetap run api -- cargo run
teetap run web -- python manage.py runserver
kubectl logs -f mypod | teetap pipe mypod
ssh box 'tail -f /var/log/app.log' | teetap pipe remote
make serve 2>&1 | grep -v DEBUG | teetap pipe serve-filtered
teetap pm2 link                                # add all PM2 workers
teetap run --rotate dev -- npm run dev         # keep previous run in dev.prev.log
teetap run --split loadtest -- ./bench.sh      # one file per run
```
