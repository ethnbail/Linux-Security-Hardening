#!/usr/bin/env python3
import re, os, subprocess, json

score = 0
max_score = 100
checks = []

def add(ok, msg, weight):
    global score
    if ok: score += weight
    checks.append({"ok": ok, "msg": msg, "weight": weight})

def file_has(path, pattern):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return re.search(pattern, f.read(), re.M|re.S) is not None
    except FileNotFoundError:
        return False

# 1) UFW active
try:
    s = subprocess.run(["ufw","status"], capture_output=True, text=True)
    add("active" in s.stdout.lower(), "UFW is active", 10)
except Exception:
    add(False, "UFW is active", 0)

# 2) SSH root disabled
add(file_has("/etc/ssh/sshd_config", r"^PermitRootLogin\s+no"), "PermitRootLogin no", 10)

# 3) SSH protocol 2
add(file_has("/etc/ssh/sshd_config", r"^Protocol\s+2"), "SSH Protocol 2", 5)

# 4) PasswordAuthentication no (ok if yes in lab; lower weight)
pa_no = file_has("/etc/ssh/sshd_config", r"^PasswordAuthentication\s+no")
add(pa_no, "PasswordAuthentication no", 5)

# 5) pwquality minlen >= 12
add(file_has("/etc/security/pwquality.conf", r"^minlen\s*=\s*1[2-9]"), "pwquality minlen >= 12", 10)

# 6) unattended-upgrades config file
add(os.path.isfile("/etc/apt/apt.conf.d/20auto-upgrades"), "unattended-upgrades configured", 10)

# 7) sysctl ASLR
add(file_has("/etc/sysctl.d/99-hardening.conf", r"^kernel.randomize_va_space\s*=\s*2"), "ASLR enabled", 10)

# 8) rp_filter set
add(file_has("/etc/sysctl.d/99-hardening.conf", r"^net.ipv4.conf.all.rp_filter\s*=\s*1"), "rp_filter enabled", 10)

# 9) auditd rules present
add(os.path.isfile("/etc/audit/rules.d/hardening.rules"), "auditd rules present", 10)

# 10) fail2ban jail present
add(os.path.isfile("/etc/fail2ban/jail.local"), "fail2ban jail present", 10)

print(json.dumps({"score": score, "max": max_score, "checks": checks}, indent=2))
