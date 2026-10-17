#!/usr/bin/env bash

set -euo pipefail

readonly PROG="${0##*/}"

TARGET_DIR="${TEMPLATE_DIR:-$HOME/Templates}"
SOURCE_DIR=""
DRY_RUN=0

readonly PURGE_EXTS=(docx xlsx pptx sh)

readonly TEMPLATE_FILES=(
  "DOCX Document.docx"
  "PPTX Presentation.pptx"
  "SH Shell Script.sh"
  "XLSX Spreadsheet.xlsx"
)

info() { printf '[%s] %s\n' "$PROG" "$*"; }
die()  { printf '[%s] error: %s\n' "$PROG" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $PROG [OPTIONS]

Wipes .docx/.xlsx/.pptx/.sh files from the target directory and reinstalls
the standard templates.

Options:
  -n, --dry-run      Show what would be done, change nothing
  -s, --source DIR   Copy templates from DIR (otherwise blank files are created)
  -t, --target DIR   Target directory (default: \$HOME/Templates)
  -h, --help         Show this help

Environment:
  TEMPLATE_DIR       Same effect as --target
EOF
}

# Run a command, or merely print it when in dry-run mode.
run() {
  if (( DRY_RUN )); then
    printf '    would run: %s\n' "$*"
  else
    "$@"
  fi
}

# --- parse arguments --------------------------------------------------------
while (( $# > 0 )); do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -s|--source)  (( $# >= 2 )) || die "--source requires a directory"
                  SOURCE_DIR="$2"; shift ;;
    -t|--target)  (( $# >= 2 )) || die "--target requires a directory"
                  TARGET_DIR="$2"; shift ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; break ;;
    -*)           die "unknown option: $1 (try --help)" ;;
    *)            die "unexpected argument: $1" ;;
  esac
  shift
done
(( $# == 0 )) || die "unexpected argument: $1"

# Normalise: drop trailing slashes so path stripping below behaves.
TARGET_DIR="${TARGET_DIR%/}"
SOURCE_DIR="${SOURCE_DIR%/}"

# --- validate ---------------------------------------------------------------
[[ -n "$TARGET_DIR" ]] || die "target directory is empty"

if [[ ! -d "$TARGET_DIR" ]]; then
  info "creating missing target directory: $TARGET_DIR"
  run mkdir -p -- "$TARGET_DIR"
fi
[[ -d "$TARGET_DIR" ]] || die "'$TARGET_DIR' is not a directory"

# This script deletes things, so refuse obviously wrong targets.
resolved="$(realpath -m -- "$TARGET_DIR")"
[[ "$resolved" != "/"    ]] || die "refusing to operate on /"
[[ "$resolved" != "$HOME" ]] || die "refusing to operate directly on \$HOME"

if [[ -n "$SOURCE_DIR" ]]; then
  [[ -d "$SOURCE_DIR" ]] || die "source directory '$SOURCE_DIR' does not exist"
  resolved_src="$(realpath -m -- "$SOURCE_DIR")"
  [[ "$resolved_src" != "$resolved" ]] || die "--source and --target are the same directory"
fi

# --- step 1: purge ----------------------------------------------------------
# Build the find predicate: -iname '*.docx' -o -iname '*.xlsx' -o ...
predicate=()
for ext in "${PURGE_EXTS[@]}"; do
  if (( ${#predicate[@]} > 0 )); then
    predicate+=(-o)
  fi
  predicate+=(-iname "*.$ext")
done

victims=()
while IFS= read -r -d '' file; do
  victims+=("$file")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 \
              \( -type f -o -type l \) \( "${predicate[@]}" \) -print0)

if (( ${#victims[@]} == 0 )); then
  info "nothing to remove in $TARGET_DIR"
else
  info "removing ${#victims[@]} file(s) from $TARGET_DIR:"
  for file in "${victims[@]}"; do
    printf '  - %s\n' "${file#"$TARGET_DIR"/}"
    run rm -f -- "$file"
  done
fi

# --- step 2: install --------------------------------------------------------
info "installing templates in $TARGET_DIR:"
for name in "${TEMPLATE_FILES[@]}"; do
  dest="$TARGET_DIR/$name"
  printf '  + %s\n' "$name"

  if [[ -n "$SOURCE_DIR" ]]; then
    src="$SOURCE_DIR/$name"
    [[ -f "$src" ]] || die "template '$name' not found in '$SOURCE_DIR'"
    run cp -- "$src" "$dest"
  elif [[ "$name" == *.sh ]]; then
    # A shell-script template is useless without a shebang and an exec bit.
    if (( DRY_RUN )); then
      printf '    would write shebang and chmod 755\n'
    else
      printf '#!/usr/bin/env bash\n' > "$dest"
      chmod 0755 -- "$dest"
    fi
  else
    run touch -- "$dest"
  fi
done

if (( DRY_RUN )); then
  info "done (dry run — nothing was changed)"
else
  info "done"
fi
