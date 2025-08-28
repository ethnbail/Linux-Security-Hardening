# CIS Controls v8 (IG1/IG2) Mapping (High-Level)

| Area | Example Control Settings | CIS Controls v8 |
|------|---------------------------|------------------|
| Inventory & Control of Enterprise Assets | Vagrant lab and documentation | 1 |
| Data Protection | AIDE baseline (integrity) | 3 |
| Secure Configuration | sysctl, SSH, UFW, PAM, Fail2ban | 4 |
| Account Management | PAM policies, password aging | 5 |
| Access Control Management | SSH key-based auth | 6 |
| Continuous Vulnerability Management | unattended-upgrades | 7 |
| Audit Log Management | auditd rules, logrotate | 8 |
| Malware Defenses | (optional) ClamAV (not installed by default) | 10 |
| Data Recovery | AIDE database re-init instructions | 11 |
| Network Infrastructure Management | UFW defaults, allowed ports | 12 |
| Security Awareness | docs/lab and checklist | 14 |
| Service Provider Management | N/A in lab | 15 |
| Application Software Security | N/A in lab | 16 |
| Incident Response Management | Fail2ban lockout evidence | 17 |

> This mapping is **illustrative**, not a formal CIS Benchmark implementation.
