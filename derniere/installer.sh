#!/usr/bin/env bash
# Super AI Agent Pro Station Max 2000 — installation sur Mac et Linux.
# Dans un Terminal :  curl -fsSL https://raw.githubusercontent.com/marechalmelchior-cpu/super-ai-studio/main/derniere/installer.sh | bash
# Pour toi seulement, sans droits administrateur ; ne supprime rien. Réinstaller = mettre à jour le programme (tes données restent).
set -euo pipefail
DEPOT="${STUDIO_DEPOT:-marechalmelchior-cpu/super-ai-studio}"
BASE="${STUDIO_BASE:-https://raw.githubusercontent.com/$DEPOT/main/derniere}"
DEST="${STUDIO_DEST:-$HOME/Super AI Studio}"
APP="$DEST/app"
NOM="Super AI Agent Pro Station Max 2000"
dire() { printf '\n\033[1;36m%s\033[0m\n' "$*"; }
stop() { printf '\n\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

cd "$HOME"                                   # le dossier courant du Terminal peut avoir été supprimé (réinstallation)
dire "Installation de $NOM"
PY=""
# Python 3.11 à 3.13 : les composants du studio n'existent pas encore pour les versions plus récentes
for c in python3.13 python3.12 python3.11 /Library/Frameworks/Python.framework/Versions/3.13/bin/python3 \
         /Library/Frameworks/Python.framework/Versions/3.12/bin/python3 /opt/homebrew/bin/python3.12 /usr/local/bin/python3.12 python3; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if (3, 11) <= sys.version_info[:2] <= (3, 13) else 1)' 2>/dev/null; then PY="$(command -v "$c")"; break; fi
done
if [ -z "$PY" ]; then
  if [ "$(uname)" = "Darwin" ]; then stop "Il faut Python 3.12 (les versions 3.11 à 3.13 conviennent ; une version plus récente ne marche pas encore) : installe « Python 3.12 » depuis https://www.python.org/downloads/macos/ (ou : brew install python@3.12), puis relance cette commande."
  else stop "Python 3.11 à 3.13 est nécessaire. Ubuntu/Debian : sudo apt install python3 python3-venv · Fedora : sudo dnf install python3 — puis relance cette commande."; fi
fi
"$PY" -c 'import venv, ensurepip' 2>/dev/null || stop "Il manque le module venv de Python. Ubuntu/Debian : sudo apt install python3-venv — puis relance cette commande."
echo "Python : $PY"
command -v curl >/dev/null || stop "curl est nécessaire."

dire "Téléchargement du programme…"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$BASE/manifest.json" -o "$TMP/manifest.json"
FICHIER="$("$PY" -c 'import json,sys; print(json.load(open(sys.argv[1]))["fichier"])' "$TMP/manifest.json")"
ATTENDU="$("$PY" -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' "$TMP/manifest.json")"
VERSION="$("$PY" -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$TMP/manifest.json")"
curl -fL --progress-bar "$BASE/$FICHIER" -o "$TMP/programme.zip"
RECU="$("$PY" -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$TMP/programme.zip")"
[ "$RECU" = "$ATTENDU" ] || stop "Le fichier téléchargé est abîmé (empreinte différente) : installation arrêtée, rien n'a été modifié."

dire "Installation de la version $VERSION dans « $DEST »…"
mkdir -p "$APP"
"$PY" - "$TMP/programme.zip" "$APP" <<'PYEOF'
import sys, zipfile, pathlib
z, dest = zipfile.ZipFile(sys.argv[1]), pathlib.Path(sys.argv[2]).resolve()
for m in z.infolist():
    cible = (dest / m.filename).resolve()
    if dest not in cible.parents and cible != dest:
        raise SystemExit("Archive refusée : chemin hors du dossier.")
z.extractall(dest)
PYEOF
echo "$DEPOT" > "$APP/DEPOT"

dire "Préparation de l'environnement Python (quelques minutes la première fois)…"
[ -x "$APP/.venv/bin/python" ] || "$PY" -m venv "$APP/.venv"
"$APP/.venv/bin/python" -m pip install --disable-pip-version-check -q --upgrade pip
"$APP/.venv/bin/python" -m pip install --disable-pip-version-check -q -r "$APP/requirements.lock.txt"
( cd "$APP" && PYTHONPATH="$APP" "$APP/.venv/bin/python" -c "import studio.launcher, langgraph; print('Studio prêt')" )

dire "Raccourci…"
if [ "$(uname)" = "Darwin" ]; then
  RACC="$HOME/Desktop/$NOM.command"
  printf '#!/bin/sh\nexec /bin/sh "%s/installeur/studio.sh"\n' "$APP" > "$RACC"; chmod +x "$RACC"
  echo "Sur le Bureau : « $NOM » (double-clic)."
else
  mkdir -p "$HOME/.local/share/applications" "$HOME/.local/bin"
  printf '#!/bin/sh\nexec /bin/sh "%s/installeur/studio.sh" "$@"\n' "$APP" > "$HOME/.local/bin/super-ai-studio"; chmod +x "$HOME/.local/bin/super-ai-studio"
  cat > "$HOME/.local/share/applications/super-ai-studio.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$NOM
Comment=Ton studio IA local
Exec=/bin/sh "$APP/installeur/studio.sh"
Icon=$APP/studio/ui/static/icon-512.png
Terminal=false
Categories=Development;
DESK
  [ -d "$HOME/Desktop" ] && cp "$HOME/.local/share/applications/super-ai-studio.desktop" "$HOME/Desktop/" && chmod +x "$HOME/Desktop/super-ai-studio.desktop" || true
  echo "Dans le menu des applications : « $NOM » (ou la commande super-ai-studio)."
fi

dire "C'est installé. Ouverture du studio…"
[ -n "${STUDIO_SANS_OUVRIR:-}" ] || nohup /bin/sh "$APP/installeur/studio.sh" >/dev/null 2>&1 &
