#!/usr/bin/env bash
set -euo pipefail

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp -a "$f" "${f}.bak-$(date +%Y%m%d%H%M%S)"
  fi
}

ensure_line() {
  # ensure_line <file> <pattern> <line>
  local file="$1" pattern="$2" line="$3"
  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    sed -ri "s|$pattern|$line|" "$file"
  else
    echo "$line" >> "$file"
  fi
}
