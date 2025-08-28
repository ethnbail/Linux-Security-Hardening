# Hardening Checklist

- [ ] Update system packages
- [ ] Enable `unattended-upgrades`
- [ ] Configure UFW (deny incoming, allow SSH, allow needed services)
- [ ] Harden SSH (no root login, Protocol 2, strong ciphers/MACs/KEX)
- [ ] Enforce password policy (pwquality, PAM)
- [ ] Apply sysctl kernel/network hardening
- [ ] Enable and configure Fail2ban for SSH
- [ ] Install and initialize AIDE
- [ ] Enable and configure auditd with baseline rules
- [ ] Ensure AppArmor is enforcing
- [ ] Verify file permissions on sensitive configs
- [ ] Run verification and scoring
