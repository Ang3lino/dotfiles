#!/usr/bin/env bash
set -e

OUT="troubleshoot-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "=== OS ==="
  uname -a
  cat /etc/os-release 2>/dev/null || true

  echo -e "\n=== SSL certs ==="
  ls /usr/local/share/ca-certificates/ 2>/dev/null || echo "(empty)"
  update-ca-certificates --fresh 2>&1 | tail -1 || true

  echo -e "\n=== Env vars ==="
  env | grep -iE 'proxy|ssl|cert|ca_|node_extra' || echo "(none set)"

  echo -e "\n=== Connectivity ==="
  for url in https://google.com https://github.com https://api.github.com https://raw.githubusercontent.com https://starship.rs https://api.openai.com; do
    printf "%-45s " "$url"
    curl -sI --max-time 5 "$url" 2>&1 | head -1 || echo "FAIL"
  done

  echo -e "\n=== SSL chain: github.com ==="
  echo | openssl s_client -connect github.com:443 -servername github.com 2>&1 | grep -E 'issuer=|subject=|verify' || true

  echo -e "\n=== SSL chain: starship.rs ==="
  echo | openssl s_client -connect starship.rs:443 -servername starship.rs 2>&1 | grep -E 'issuer=|subject=|verify' || true

  echo -e "\n=== SSL chain: api.openai.com ==="
  echo | openssl s_client -connect api.openai.com:443 -servername api.openai.com 2>&1 | grep -E 'issuer=|subject=|verify' || true

  echo -e "\n=== Installed tools ==="
  for cmd in zsh tmux nvim starship lazygit fzf zoxide rg fd jq git curl openssl; do
    printf "%-12s " "$cmd"
    command -v "$cmd" 2>/dev/null && ("$cmd" --version 2>/dev/null | head -1) || echo "NOT FOUND"
  done

  echo -e "\n=== Git SSL config ==="
  git config --global --get http.sslCAInfo 2>/dev/null || echo "(not set)"
  git config --global --get http.sslVerify 2>/dev/null || echo "(default: true)"

} > "$OUT" 2>&1

echo "Saved to $OUT"
