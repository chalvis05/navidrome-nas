#!/bin/sh
# Run ON THE UGREEN NAS over SSH, from the repo folder:
#   sudo sh scripts/setup-nas.sh
# Creates folders, fixes ownership, validates .env, then starts the stack.
set -eu

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.example .env
  echo ">> Created .env from .env.example. Edit it (DEEZER_ARL, paths, PUID/PGID) and re-run."
  exit 1
fi

# Read only the keys we need (don't `source` .env: values may contain spaces/quotes)
getenv() { sed -n "s/^[[:space:]]*$1=//p" .env | tail -n1 | sed 's/\r$//; s/^["'\'']//; s/["'\'']$//'; }
APPDATA_DIR=$(getenv APPDATA_DIR); MUSIC_DIR=$(getenv MUSIC_DIR)
PUID=$(getenv PUID); PGID=$(getenv PGID); DEEZER_ARL=$(getenv DEEZER_ARL)
NAVIDROME_PORT=$(getenv NAVIDROME_PORT); OCTO_FIESTA_PORT=$(getenv OCTO_FIESTA_PORT)

case "${DEEZER_ARL:-}" in
  ""|paste_your_arl_cookie_here) echo "!! DEEZER_ARL is not set in .env"; exit 1 ;;
esac

[ -d "$MUSIC_DIR" ] || { echo "!! MUSIC_DIR $MUSIC_DIR does not exist. Create the shared folder in UGOS first."; exit 1; }

mkdir -p "$APPDATA_DIR/navidrome" "$MUSIC_DIR/octo-fiesta"
chown -R "$PUID:$PGID" "$APPDATA_DIR" "$MUSIC_DIR/octo-fiesta"

docker compose config -q
docker compose pull
docker compose up -d
docker compose ps

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo ">> Navidrome UI (create admin user first): http://${IP:-<nas-ip>}:${NAVIDROME_PORT:-4533}"
echo ">> Point your Subsonic client at octo-fiesta: http://${IP:-<nas-ip>}:${OCTO_FIESTA_PORT:-5274}"
