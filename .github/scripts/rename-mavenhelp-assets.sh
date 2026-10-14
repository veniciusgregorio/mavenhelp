#!/usr/bin/env bash
# Renomeia os instaladores do release para o padrao SuporteMV-<sistema>-<arquitetura>.
# Uso: rename-mavenhelp-assets.sh <tag> [--delete-old]
# Requer o gh autenticado (GH_TOKEN) e GITHUB_REPOSITORY ou REPO definido.
set -euo pipefail

tag="$1"
delete_old="${2:-}"
repo="${REPO:-$GITHUB_REPOSITORY}"

declare -A names=(
  [x86_64.exe]=Windows-x64.exe
  [x86_64.msi]=Windows-x64.msi
  [aarch64.exe]=Windows-ARM64.exe
  [aarch64.msi]=Windows-ARM64.msi
  [aarch64.dmg]=macOS-AppleSilicon.dmg
  [x86_64.dmg]=macOS-Intel.dmg
  [x86_64.deb]=Linux-x64.deb
  [aarch64.deb]=Linux-ARM64.deb
  [0.x86_64.rpm]=Linux-x64.rpm
  [0.aarch64.rpm]=Linux-ARM64.rpm
  [0.x86_64-suse.rpm]=Linux-x64-openSUSE.rpm
  [0.aarch64-suse.rpm]=Linux-ARM64-openSUSE.rpm
  [0-x86_64.pkg.tar.zst]=Linux-x64-Arch.pkg.tar.zst
)

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

gh release download "$tag" -R "$repo" -p 'rustdesk-*' -D "$work"

renamed=()
originals=()
for path in "$work"/rustdesk-*; do
  name="$(basename "$path")"
  rest="${name#rustdesk-}"
  rest="${rest#*-}" # remove a versao
  new="${names[$rest]:-}"
  if [[ -z "$new" ]]; then
    echo "Sem nome definido para $name, mantido como esta"
    continue
  fi
  mv "$path" "$work/SuporteMV-$new"
  renamed+=("$work/SuporteMV-$new")
  originals+=("$name")
  echo "$name -> SuporteMV-$new"
done

gh release upload "$tag" -R "$repo" --clobber "${renamed[@]}"

if [[ "$delete_old" == "--delete-old" ]]; then
  for name in "${originals[@]}"; do
    gh release delete-asset "$tag" "$name" -R "$repo" -y
  done
fi
