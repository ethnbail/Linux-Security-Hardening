# Architecture & Threat Model (Brief)

**Threat model** (lab/demo):
- Single Ubuntu host exposed via SSH.
- Risk: brute-force SSH, weak passwords, vulnerable services, kernel-level misconfig, lack of audit visibility.

**Objectives**:
- Reduce remote attack surface (firewall).
- Strengthen authentication and SSH transport.
- Enforce password complexity & aging.
- Harden kernel network stack.
- Add tamper detection (AIDE) and audit visibility (auditd).
- Automate and verify controls (Ansible + scoring).

**Non-goals**:
- Full CIS Benchmark coverage.
- SELinux policies (we use AppArmor in Ubuntu).
- Application-level hardening (databases, web servers).
