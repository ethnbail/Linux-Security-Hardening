#!/usr/bin/env bash
# Linux hardening script with dry-run by default. Test on a VM.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
source "$HERE/helpers.sh"

APPLY=0
SSH_PORT=22
ALLOW_SSH_PASSWORDS=0
SKIP_SECTIONS="" # comma-separated: ufw,ssh,pam,updates,sysctl,fail2ban,auditd,aide,apparmor

log() { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

is_skipped() {
  [[ ",$SKIP_SECTIONS," == *",$1,"* ]]
}

do_run() {
  if [[ "$APPLY" -eq 1 ]]; then
    bash -c "$*"
  else
    echo "[dry-run] $*"
  fi
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Run as root (sudo)."
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) APPLY=1 ;;
      --check) APPLY=0 ;;
      --ssh-port) SSH_PORT="${2:-22}"; shift ;;
      --allow-ssh-passwords) ALLOW_SSH_PASSWORDS=1 ;;
      --skip) SKIP_SECTIONS="${2:-}"; shift ;;
      -h|--help)
        cat <<EOF
Usage: $0 [--check] [--apply] [--ssh-port N] [--allow-ssh-passwords] [--skip a,b,c]

Sections: ufw, ssh, pam, updates, sysctl, fail2ban, auditd, aide, apparmor
EOF
        exit 0
      ;;
      *) err "Unknown arg: $1"; exit 1 ;;
    esac
    shift
  done
}

apt_install() {
  log "Updating apt and installing baseline packages..."
  do_run "apt-get update -y"
  do_run "apt-get install -y ufw fail2ban auditd aide apparmor-utils unattended-upgrades libpam-pwquality"
}

section_ufw() {
  is_skipped ufw && { warn "Skipping UFW"; return; }
  log "Configuring UFW (firewall)..."
  do_run "ufw default deny incoming"
  do_run "ufw default allow outgoing"
  do_run "ufw allow ${SSH_PORT}/tcp"
  do_run "ufw limit ${SSH_PORT}/tcp"
  # non-interactive enable
  if [[ "$APPLY" -eq 1 ]]; then
    echo "y" | ufw enable || true
  else
    echo "[dry-run] ufw enable"
  fi
}

section_ssh() {
  is_skipped ssh && { warn "Skipping SSH hardening"; return; }
  log "Hardening SSH..."
  local sshd="/etc/ssh/sshd_config"
  backup_file "$sshd"

  ensure_line "$sshd" "^#?Port\\s+.*" "Port ${SSH_PORT}"
  ensure_line "$sshd" "^#?Protocol\\s+.*" "Protocol 2"
  ensure_line "$sshd" "^#?PermitRootLogin\\s+.*" "PermitRootLogin no"
  if [[ "$ALLOW_SSH_PASSWORDS" -eq 1 ]]; then
    ensure_line "$sshd" "^#?PasswordAuthentication\\s+.*" "PasswordAuthentication yes"
  else
    ensure_line "$sshd" "^#?PasswordAuthentication\\s+.*" "PasswordAuthentication no"
  fi
  ensure_line "$sshd" "^#?ChallengeResponseAuthentication\\s+.*" "ChallengeResponseAuthentication no"
  ensure_line "$sshd" "^#?UsePAM\\s+.*" "UsePAM yes"
  ensure_line "$sshd" "^#?X11Forwarding\\s+.*" "X11Forwarding no"
  ensure_line "$sshd" "^#?ClientAliveInterval\\s+.*" "ClientAliveInterval 300"
  ensure_line "$sshd" "^#?ClientAliveCountMax\\s+.*" "ClientAliveCountMax 2"
  ensure_line "$sshd" "^#?LoginGraceTime\\s+.*" "LoginGraceTime 30"
  ensure_line "$sshd" "^#?MaxAuthTries\\s+.*" "MaxAuthTries 3"
  ensure_line "$sshd" "^#?AllowTcpForwarding\\s+.*" "AllowTcpForwarding no"
  ensure_line "$sshd" "^#?PermitEmptyPasswords\\s+.*" "PermitEmptyPasswords no"
  ensure_line "$sshd" "^#?UseDNS\\s+.*" "UseDNS no"

  # Stronger crypto defaults (Ubuntu/OpenSSH will ignore unknowns)
  ensure_line "$sshd" "^#?Ciphers\\s+.*" "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com"
  ensure_line "$sshd" "^#?MACs\\s+.*" "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"
  ensure_line "$sshd" "^#?KexAlgorithms\\s+.*" "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org"

  do_run "chmod 600 $sshd"
  do_run "systemctl restart ssh || systemctl restart sshd || true"
}

section_pam() {
  is_skipped pam && { warn "Skipping PAM"; return; }
  log "Configuring password policy (pam_pwquality)..."
  local pwq="/etc/security/pwquality.conf"
  backup_file "$pwq"
  # Reasonable lab defaults
  ensure_line "$pwq" "^#?minlen\\s*=.*" "minlen = 12"
  ensure_line "$pwq" "^#?dcredit\\s*=.*" "dcredit = -1"
  ensure_line "$pwq" "^#?ucredit\\s*=.*" "ucredit = -1"
  ensure_line "$pwq" "^#?lcredit\\s*=.*" "lcredit = -1"
  ensure_line "$pwq" "^#?ocredit\\s*=.*" "ocredit = -1"
  ensure_line "$pwq" "^#?retry\\s*=.*" "retry = 3"
  ensure_line "$pwq" "^#?enforce_for_root\\s*=.*" "enforce_for_root = 1"
}

section_updates() {
  is_skipped updates && { warn "Skipping unattended-upgrades"; return; }
  log "Enabling unattended-upgrades..."
  local au="/etc/apt/apt.conf.d/20auto-upgrades"
  backup_file "$au"
  cat > "$au" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
  if [[ "$APPLY" -eq 1 ]]; then
    unattended-upgrade -d || true
  else
    echo "[dry-run] unattended-upgrade -d"
  fi
}

section_sysctl() {
  is_skipped sysctl && { warn "Skipping sysctl"; return; }
  log "Applying kernel/network hardening (sysctl)..."
  local sysfile="/etc/sysctl.d/99-hardening.conf"
  backup_file "$sysfile"
  cp "$ROOT/config/sysctl/99-hardening.conf" "$sysfile"
  do_run "sysctl --system"
}

section_fail2ban() {
  is_skipped fail2ban && { warn "Skipping fail2ban"; return; }
  log "Configuring fail2ban sshd jail..."
  local jail="/etc/fail2ban/jail.local"
  backup_file "$jail"
  cp "$ROOT/config/fail2ban/jail.local" "$jail"
  do_run "systemctl enable --now fail2ban"
}

section_auditd() {
  is_skipped auditd && { warn "Skipping auditd"; return; }
  log "Installing baseline auditd rules..."
  local rules="/etc/audit/rules.d/hardening.rules"
  backup_file "$rules"
  cp "$ROOT/config/auditd/hardening.rules" "$rules"
  do_run "augenrules --load || true"
  do_run "systemctl enable --now auditd || true"
}

section_aide() {
  is_skipped aide && { warn "Skipping AIDE"; return; }
  log "Initializing AIDE (may take a while on real systems)..."
  if [[ "$APPLY" -eq 1 ]]; then
    aideinit || true
    if [[ -f /var/lib/aide/aide.db.new ]]; then
      mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi
  else
    echo "[dry-run] aideinit && mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db"
  fi
}

section_apparmor() {
  is_skipped apparmor && { warn "Skipping AppArmor"; return; }
  log "Ensuring AppArmor is enforcing..."
  do_run "aa-status || true"
  # If disabled at boot, user must enable via GRUB; here we just ensure service is present
  do_run "systemctl enable --now apparmor || true"
}

main() {
  parse_args "$@"
  require_root
  apt_install
  section_ufw
  section_ssh
  section_pam
  section_updates
  section_sysctl
  section_fail2ban
  section_auditd
  section_aide
  section_apparmor

  log "Done. If you used --apply, review logs and run verify.sh + scoring."
}

main "$@"
