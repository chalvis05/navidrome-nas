# Navidrome + octo-fiesta on a UGREEN NAS (Docker)

A self-hosted music server for UGREEN UGOS Pro (DXP2800 / DXP4800 / DXP4800 Plus / DXP6800 / DXP8800 ...).

- **Navidrome**: indexes your music library and serves it over the Subsonic API plus a web UI.
- **octo-fiesta**: a Subsonic proxy that sits in front of Navidrome. When you search for something that isn't in your library, it shows Deezer results too. When you play one, it downloads the track into your library and Navidrome indexes it.

```
Phone / desktop client ──► octo-fiesta :5274 ──► Navidrome :4533 (internal network)
                                 │
                                 └──► Deezer ──► /volume1/Music/octo-fiesta/
```

> Downloading from Deezer with an ARL may break Deezer's Terms of Service. You are responsible for how you use it. Keep `STORAGE_MODE=Cache` if you only want temporary files.

---

## 1. Requirements

| Item | Notes |
|---|---|
| UGREEN NAS on UGOS Pro | The **Docker** app installed from the App Center |
| SSH enabled | Control Panel → Terminal → enable SSH (port 22). You can switch it off again afterwards |
| Deezer account | Premium/HiFi for FLAC; Free works with `DEEZER_QUALITY=MP3_128` |
| (optional) GitHub CLI on your PC | To publish this repo and open the PR (`scripts/open-pr.ps1`) |

## 2. Prepare shared folders (UGOS web UI)

1. Open **Files** and make sure the shared folder `Music` exists on `volume1`. If not, create it from Control Panel → Shared Folder. This is `MUSIC_DIR`.
2. Make sure the `docker` shared folder exists. The Docker app usually creates it. Inside it, create `music-stack`. This becomes `APPDATA_DIR`.
3. Copy your existing music into `Music` (any folder layout works; Navidrome reads the tags).

> Path check: in an SSH session, run `ls /volume1`. If your pool is on `volume2`, change the paths in `.env`.

## 3. Get your Deezer ARL

1. Log in at https://www.deezer.com in a desktop browser.
2. Open DevTools (F12) → **Application** (Chrome/Edge) or **Storage** (Firefox) → **Cookies** → `https://www.deezer.com`.
3. Copy the value of the `arl` cookie (about 190 hex characters). Treat it like a password.

## 4. Copy the project to the NAS

**Option A, git over SSH (recommended):**

```sh
ssh <your-ugos-user>@<nas-ip>
sudo -i
cd /volume1/docker/music-stack
git clone https://github.com/<you>/navidrome-nas.git .   # after you've pushed it (step 9)
```

**Option B, without git:** in the UGOS **Files** app, upload this folder's contents (`docker-compose.yml`, `.env.example`, `scripts/`) into `docker/music-stack`.

## 5. Configure `.env`

```sh
cd /volume1/docker/music-stack
cp .env.example .env
id <your-ugos-user>        # e.g. uid=1000 gid=10(admin) -> PUID=1000, PGID=10
vi .env                    # or edit it in the Files app with the text editor
```

At minimum, set `DEEZER_ARL`, `PUID`, `PGID`, `MUSIC_DIR`, `APPDATA_DIR`, and `TZ`.

## 6. Deploy

### 6a. SSH (one command)

```sh
sudo sh scripts/setup-nas.sh
```

This validates `.env`, creates `APPDATA_DIR/navidrome` and `MUSIC_DIR/octo-fiesta`, fixes ownership, then runs `docker compose pull && up -d`.

### 6b. Or the UGOS Docker app UI

1. Docker → **Project** → **Create**.
2. Name: `music`. Storage path: `/volume1/docker/music-stack`.
3. Choose **Import docker-compose.yml** and select the file. UGOS reads `.env` from the same folder.
4. Create the folders `docker/music-stack/navidrome` and `Music/octo-fiesta` in Files first, and give your user read/write permission.
5. Click **Deploy**.

### Build octo-fiesta from source instead of pulling the image

In `docker-compose.yml`, under `octo-fiesta:`, uncomment the `build:` block. Then run:

```sh
docker compose build --pull octo-fiesta
docker compose up -d
```

The DXP series is x86-64, so the build works natively. The first build takes a few minutes.

## 7. First run

1. Open **`http://<nas-ip>:4533`** and create the Navidrome **admin** account. The first user to log in becomes admin.
2. Wait for the first scan to finish (Settings → About, or watch `docker logs -f navidrome`).
3. In your client, add a **Subsonic / Navidrome** server:
   - URL: **`http://<nas-ip>:5274`** (octo-fiesta, *not* 4533)
   - User and password: your Navidrome account
   - If the client has a "legacy auth / plain password" toggle and login fails, try switching it.

Tested-friendly clients include Symfonium (Android), Feishin (desktop), Substreamer and play:Sub (iOS), and DSub.

4. Search for a song you don't own. Deezer results appear next to local ones. Play one; it downloads to `Music/octo-fiesta/` and shows up in Navidrome after the watcher or scan runs.

## 8. Remote access (optional)

Pick one:

- **Tailscale** (simplest and safest): install it from the UGOS App Center, then use `http://<tailscale-ip>:5274` from anywhere.
- **Reverse proxy with HTTPS** (Nginx Proxy Manager or Caddy in Docker): proxy `music.example.com` to `octo-fiesta:5274` and keep 4533 LAN-only. Don't port-forward 4533 or 5274 directly to the internet without TLS.
- UGREENlink does not tunnel arbitrary Docker ports.

## 9. Publish to GitHub and open the PR (on your Windows PC)

This folder is already a git repo with two branches:

- `main` holds a minimal initial commit.
- `feat/navidrome-octo-fiesta-ugreen` holds the full stack and is the PR branch.

```powershell
winget install GitHub.cli
gh auth login
cd $HOME\Documents\navidrome
.\scripts\open-pr.ps1 -Repo navidrome-nas      # add -Public for a public repo
```

The script creates `github.com/<you>/navidrome-nas`, pushes both branches, opens the PR using `PULL_REQUEST.md` as the description, and opens it in your browser. It refuses to run if `.env` is tracked.

If PowerShell blocks the script, run `Set-ExecutionPolicy -Scope Process Bypass` first.

## 10. Operations

| Task | Command (SSH, in `/volume1/docker/music-stack`) |
|---|---|
| Status | `docker compose ps` |
| Logs | `docker compose logs -f octo-fiesta` / `navidrome` |
| Update | `docker compose pull && docker compose up -d && docker image prune -f` |
| Restart | `docker compose restart` |
| Stop | `docker compose down` |
| Backup | Back up `APPDATA_DIR/navidrome` (database: users, playlists, play counts) and `Music` |

## 11. Troubleshooting

| Symptom | Fix |
|---|---|
| `DEEZER_ARL must be set` | Fill `DEEZER_ARL` in `.env` |
| `permission denied` writing `/music/octo-fiesta` or `/data` | Run `id` again, correct `PUID`/`PGID`, then `sudo chown -R PUID:PGID` on those folders |
| Client can't log in through 5274 but can through 4533 | Check `docker logs octo-fiesta`; confirm `Subsonic__Url` reaches `http://navidrome:4533` (`docker exec octo-fiesta wget -qO- http://navidrome:4533/ping`) |
| Deezer results empty or downloads fail | The ARL has expired (it changes when you log out). Grab a new one and run `docker compose up -d` |
| Downloaded tracks don't appear | Wait for the scan, or trigger one in Navidrome UI → Settings → Scan. Lower `ND_SCANNER_SCHEDULE` if needed |
| Port conflict on 4533 or 5274 | Change `NAVIDROME_PORT` / `OCTO_FIESTA_PORT` in `.env` |
| octo-fiesta settings not applied | The upstream project may have renamed config keys. Compare the `environment:` block with the upstream README (`https://github.com/V1ck3s/octo-fiesta`) and adjust |

## Files

```
docker-compose.yml     the stack
.env.example           configuration template (copy to .env)
scripts/setup-nas.sh   NAS-side bootstrap (SSH)
scripts/open-pr.ps1    PC-side: create GitHub repo + open the PR
PULL_REQUEST.md        PR description
```
