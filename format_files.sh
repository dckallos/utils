#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# format_files.sh – Markdown snapshot + extension map (emoji edition)
# Compatible with the macOS default /bin/bash (no associative arrays)
#
# Usage:
#   ./format_files.sh file1 [file2 …]
#
# Outputs:
#   output/code-snapshot.md   – combined sources with emoji section headers
#   output/extension-map.md   – table mapping extensions to fence tags & emojis
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# ---------- helper: map extension → language tag ----------------------------
lang_of() {
  case "$1" in
    py)            echo python ;;
    sh|bash)       echo bash ;;
    csv)           echo csv ;;
    js)            echo javascript ;;
    ts)            echo typescript ;;
    json)          echo json ;;
    c|h)           echo c ;;
    cpp)           echo cpp ;;
    java)          echo java ;;
    go)            echo go ;;
    rb)            echo ruby ;;
    php)           echo php ;;
    cs)            echo csharp ;;
    swift)         echo swift ;;
    html)          echo html ;;
    css)           echo css ;;
    yaml|yml)      echo yaml ;;
    toml)          echo toml ;;
    *)             echo "$1" ;;
  esac
}

# ---------- helper: map extension → emoji -----------------------------------
emoji_of() {
  case "$1" in
    py)            echo "🐍" ;;
    sh|bash)       echo "🐚" ;;
    csv)           echo "📊" ;;
    js|ts)         echo "✨" ;;
    json)          echo "🔧" ;;
    c|cpp)         echo "💻" ;;
    h)             echo "📑" ;;
    java)          echo "☕️" ;;
    go)            echo "🚀" ;;
    rb)            echo "💎" ;;
    php)           echo "🐘" ;;
    cs)            echo "🎯" ;;
    swift)         echo "🕊️" ;;
    html)          echo "🌐" ;;
    css)           echo "🎨" ;;
    yaml|yml)      echo "📜" ;;
    toml)          echo "🗄️" ;;
    *)             echo "📄" ;;
  esac
}

# ---------- helper: exit with message ---------------------------------------
die() {
  printf >&2 "✖ %s\n" "$*"
  exit 1
}

# ---------- helper: build N back-ticks --------------------------------------
make_ticks() {
  printf '%.0s`' $(seq "$1")
}

# ---------- helper: choose collision-free opening fence ---------------------
pick_fence() {
  local file=$1
  local lang=$2
  local ticks=3
  local bt
  while :; do
    bt=$(make_ticks "$ticks")
    if ! grep -Fq "$bt" "$file"; then
      printf '%s%s' "$bt" "$lang"
      return
    fi
    ((ticks++))
  done
}

# ---------- helper: write one section to snapshot ---------------------------
write_block() {
  local file=$1
  local open=$2
  local ext=$3
  printf '## %s **%s**\n\n' "$(emoji_of "$ext")" "$(basename "$file")" >>"$SNAP"
  printf '%s\n' "$open" >>"$SNAP"
  cat -- "$file" >>"$SNAP"
  printf '\n' >>"$SNAP"
  printf '%s\n\n' "${open%%[a-zA-Z0-9]*}" >>"$SNAP"
}

# ---------- argument check ---------------------------------------------------
(( $# )) || die "Usage: $0 file1 [file2 …]"

# ---------- prepare output files --------------------------------------------
mkdir -p output
SNAP="output/code-snapshot.md"
MAP="output/extension-map.md"
: >"$SNAP"
: >"$MAP"

seen_exts=""
sections=0

# ---------- main loop --------------------------------------------------------
for f in "$@"; do
  if [[ ! -f $f ]]; then
    printf >&2 "⚠️  Skipping \"%s\" (not found)\n" "$f"
    continue
  fi

  ext=${f##*.}
  lang=$(lang_of "$ext")
  fence=$(pick_fence "$f" "$lang")
  write_block "$f" "$fence" "$ext"

  case " $seen_exts " in
    *" $ext "*) ;;
    *) seen_exts="$seen_exts $ext" ;;
  esac

  ((sections++))
done

(( sections )) || die "No valid files processed."

# ---------- build extension-map.md ------------------------------------------
printf '# ✨ Extension → Markdown Fence Map\n\n' >>"$MAP"
printf '| Extension | Fence Tag | Emoji |\n' >>"$MAP"
printf '|-----------|-----------|-------|\n' >>"$MAP"
for ext in $seen_exts; do
  lang=$(lang_of "$ext")
  printf '| .%s | ```%s | %s |\n' "$ext" "$lang" "$(emoji_of "$ext")" >>"$MAP"
done
printf '\n' >>"$MAP"

printf '✅  Wrote %d section(s) to %s and extension map to %s 🎉\n' \
       "$sections" "$SNAP" "$MAP"
