## Summary

Adds a Docker Compose stack that runs **Navidrome** (music server) behind **octo-fiesta** (Subsonic proxy that fetches missing tracks from Deezer) on a **UGREEN NAS (UGOS Pro / DXP series)**, plus a step-by-step deployment guide.

## What's included

- `docker-compose.yml`: two services on a private `music` network. Navidrome mounts the library read-only; octo-fiesta mounts it read-write and downloads into `MUSIC_DIR/octo-fiesta`. octo-fiesta waits for Navidrome's `/ping` healthcheck. Supports the upstream image (default) or building octo-fiesta from source via a git build context.
- `.env.example`: all paths, PUID/PGID, ports, Deezer ARL/quality, and download behaviour in one place. `DEEZER_ARL` is required (compose fails fast if missing).
- `scripts/setup-nas.sh`: run over SSH on the NAS; validates `.env`, creates folders, fixes ownership, then pulls and starts the stack.
- `scripts/open-pr.ps1`: creates the GitHub repo and opens this PR via `gh`.
- `README.md`: UGOS Pro guide (shared folders, SSH, Docker app "Project" import, client setup, remote access, updates, troubleshooting).

## Security

- `.env` is git-ignored; the PR script refuses to push if it is tracked.
- Navidrome's library mount is read-only; only octo-fiesta can write, and only where it downloads to.

## Test plan

- [ ] `docker compose config -q` passes with a filled-in `.env`
- [ ] `sudo sh scripts/setup-nas.sh` on the NAS brings both containers up (`navidrome` healthy)
- [ ] Create Navidrome admin at `http://<nas-ip>:4533`
- [ ] Subsonic client pointed at `http://<nas-ip>:5274` logs in with the Navidrome account
- [ ] Searching a track that isn't in the library returns Deezer results; playing it downloads into `Music/octo-fiesta/` and it appears in Navidrome after the scan
