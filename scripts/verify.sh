#!/usr/bin/env bash
set -euo pipefail

pass() { printf "\033[1;32m[PASS]\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m[FAIL]\033[0m %s\n" "$*"; }

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then pass "found $1"; else fail "missing $1"; fi
}

check_file_has() {
  local f="$1" pat="$2" msg="$3"
  if [[ -f "$f" ]] && grep -Eq "$pat" "$f"; then pass "$msg"; else fail "$msg"; fi
}

# Basic checks
check_cmd ufw
check_cmd sshd || check_cmd ssh
check_cmd auditctl || true
check_cmd aide || true
check_cmd fail2ban-client || true

# UFW
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -qi "active"; then pass "UFW active"; else fail "UFW not active"; fi
  if ufw status | grep -qi "22/tcp"; then pass "SSH allowed (port 22 or custom)"; else fail "SSH not allowed in UFW (ensure your custom port is allowed)"; fi
fi

# SSH
check_file_has /etc/ssh/sshd_config "^PermitRootLogin\\s+no" "SSH root login disabled"
check_file_has /etc/ssh/sshd_config "^Protocol\\s+2" "SSH Protocol 2 set"
if grep -Eq "^PasswordAuthentication\\s+no" /etc/ssh/sshd_config 2>/dev/null; then
  pass "SSH password auth disabled"
else
  echo "Note: PasswordAuthentication not 'no' (OK in lab)."
fi

# PAM
check_file_has /etc/security/pwquality.conf "^minlen\\s*=\\s*12" "pwquality minlen >= 12"
check_file_has /etc/security/pwquality.conf "^enforce_for_root\\s*=\\s*1" "pwquality enforce_for_root"

# Updates
if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then
  pass "unattended-upgrades config present"
else
  fail "unattended-upgrades config missing"
fi

# sysctl
check_file_has /etc/sysctl.d/99-hardening.conf "^net.ipv4.conf.all.rp_filter\\s*=\\s*1" "rp_filter configured"
check_file_has /etc/sysctl.d/99-hardening.conf "^kernel.randomize_va_space\\s*=\\s*2" "ASLR enabled"

# auditd
if systemctl is-active --quiet auditd 2>/dev/null; then pass "auditd running"; else echo "[INFO] auditd not active (OK in some containers)"; fi
if [[ -f /etc/audit/rules.d/hardening.rules ]]; then pass "auditd rules installed"; else fail "auditd rules missing"; fi

# fail2ban
if systemctl is-active --quiet fail2ban 2>/dev/null; then pass "fail2ban running"; else echo "[INFO] fail2ban not active"; fi

# AIDE
if [[ -f /var/lib/aide/aide.db ]]; then pass "AIDE baseline present"; else echo "[INFO] AIDE db missing (init may be pending)"; fi
