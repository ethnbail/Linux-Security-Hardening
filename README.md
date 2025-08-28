# Linux Security Hardening Project

A hands-on, portfolio-ready project that demonstrates **Linux security hardening** on an Ubuntu Server VM (22.04/24.04).
It includes:
- An **idempotent Bash hardening script** with safe defaults and a dry-run mode.
- A **verification script** and a **Python scoring tool** to validate controls.
- An **Ansible playbook** that applies the same controls declaratively.
- A **Vagrant lab** to spin up a disposable Ubuntu VM and practice safely.
- Clear **docs**, **checklists**, and a **CIS Controls v8** mapping.

> ⚠️ **Warning**: Hardening changes can lock you out (e.g., firewall rules, SSH config). Test on a VM first.

## Quickstart

### Option A — Lab VM (recommended)
1. Install: VirtualBox, Vagrant.
2. In this folder, run:
   ```bash
   vagrant up
   vagrant ssh
   ```
3. Inside the VM:
   ```bash
   cd /vagrant
   sudo ./scripts/hardening.sh --check      # dry-run preview of changes
   sudo ./scripts/hardening.sh --apply      # apply changes (read warnings below)
   sudo ./scripts/verify.sh                 # quick verification
   python3 ./scoring/score.py               # 0–100 score
   ```

### Option B — Local (on your own Linux box / cloud VM)
```bash
sudo ./scripts/hardening.sh --check
sudo ./scripts/hardening.sh --apply --ssh-port 22
sudo ./scripts/verify.sh
python3 ./scoring/score.py
```

### What gets hardened
- **Firewall (UFW)**: default deny incoming, allow SSH (rate-limited), allow only what you need.
- **SSH**: Protocol 2, disable root login, strong ciphers/MACs/KEX, optional password disable.
- **PAM / Password policy**: `libpam-pwquality` controls for minimum length/complexity/history.
- **Automatic security updates**: `unattended-upgrades` enabled.
- **Kernel/sysctl**: anti-spoofing, no source routing, no redirects, rp_filter, ASLR, etc.
- **Auditd**: baseline rules for auth files, important binaries, and immutable end state.
- **Fail2ban**: simple `sshd` jail with sane bantime/findtime.
- **AIDE**: file integrity baseline initialized.
- **AppArmor**: ensure profiles are enforced.
- **Permissions & ownership**: ensure key files are restrictive.

For a full checklist and control mapping, see: `docs/checklist.md` and `docs/controls-mapping.md`.

## Safety levers
- Run with `--check` for a full dry run.
- Use `--ssh-port <PORT>` to keep your current SSH port reachable.
- Use `--allow-ssh-passwords` if you use password auth (recommended only for labs).
- Skip sections: `--skip ufw,ssh,auditd,aide,sysctl,fail2ban,updates,pam,apparmor`

## Repo structure
```
linux-hardening-project/
├─ README.md
├─ LICENSE
├─ SECURITY.md
├─ CITATION.cff
├─ docs/
│  ├─ lab.md
│  ├─ checklist.md
│  ├─ controls-mapping.md
│  └─ architecture.md
├─ scripts/
│  ├─ hardening.sh
│  ├─ verify.sh
│  └─ helpers.sh
├─ config/
│  ├─ sysctl/99-hardening.conf
│  ├─ auditd/hardening.rules
│  ├─ fail2ban/jail.local
│  ├─ ssh/sshd_config.hardening
│  ├─ apt/20auto-upgrades
│  ├─ pam/pwquality.conf
│  └─ aide/aide.conf.sample
├─ ansible/
│  ├─ inventory.ini
│  └─ site.yml
├─ scoring/
│  └─ score.py
├─ Vagrantfile
└─ .github/workflows/lint.yml
```

## Credits & License
MIT License — see `LICENSE`. This project is intended for educational use.
