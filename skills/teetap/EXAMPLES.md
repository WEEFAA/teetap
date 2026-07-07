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
awk '/ERROR/{print $1}' "$DIR"/dev.log | uniq -c        # errors per timestamp prefix
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
awk '/teetap session .* start/{n=NR} {l[NR]=$0} END{for(i=n;i<=NR;i++) print l[i]}' "$DIR"/dev.log
```

Then compare with the previous session if the developer used `--rotate`:

```sh
grep -c "ERROR" "$DIR"/dev.prev.log "$DIR"/dev.log     # error count, before vs after
```

## Walkthrough: machine-wide view (everything the developer runs)

```sh
ROOT=${TEETAP_DIR:-$HOME/.local/state/teetap}
ls "$ROOT"                                     # one directory per project/worktree
tail -f "$ROOT"/*/*.log                        # follow everything live
grep -l "OOM" "$ROOT"/*/*.log                  # which project hit it?
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
