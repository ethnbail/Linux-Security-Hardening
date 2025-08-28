# Hands-on Lab (Ubuntu VM)

This lab spins up an Ubuntu Server VM with Vagrant, then applies hardening using both **Bash** and **Ansible**.

## Prereqs
- VirtualBox and Vagrant installed.
- ~2 GB free RAM and 10 GB disk.

## Steps
```bash
vagrant up
vagrant ssh
cd /vagrant

# Preview changes
sudo ./scripts/hardening.sh --check

# Apply changes (careful: firewall + SSH changes)
sudo ./scripts/hardening.sh --apply --ssh-port 22 --allow-ssh-passwords

# Verify
sudo ./scripts/verify.sh
python3 ./scoring/score.py

# Try the Ansible way
sudo ansible-playbook -i ansible/inventory.ini ansible/site.yml --connection=local
```
> Tip: You can destroy and rebuild quickly with `vagrant destroy -f && vagrant up`.
