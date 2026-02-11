#!/usr/bin/env bash
set -euo pipefail

# Idempotent Ubuntu server security hardening script.
# Configures: fail2ban, unattended-upgrades, SSH hardening,
# and a weekly reboot timer.
#
# Usage: sudo ./secure-ubuntu-server.sh

if [[ $EUID -ne 0 ]]; then
  echo "Error: must be run as root (use sudo)" >&2
  exit 1
fi

# ── fail2ban ───────────────────────────────────────────────

echo ":: Setting up fail2ban..."

DEBIAN_FRONTEND=noninteractive \
  apt-get install -y -qq fail2ban > /dev/null

cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
maxretry = 3
bantime = 24h
EOF

systemctl enable --now fail2ban
systemctl restart fail2ban
echo "   fail2ban: OK"

# ── Unattended upgrades ───────────────────────────────────

echo ":: Setting up unattended-upgrades..."

DEBIAN_FRONTEND=noninteractive \
  apt-get install -y -qq unattended-upgrades > /dev/null

# Enable the periodic apt tasks (idempotent write)
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now unattended-upgrades
echo "   unattended-upgrades: OK"

# ── SSH hardening ─────────────────────────────────────────

echo ":: Hardening SSH..."

SSHD_DROP=/etc/ssh/sshd_config.d/99-hardening.conf

cat > "$SSHD_DROP" << 'EOF'
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin prohibit-password
EOF

# Ubuntu 24.04 uses 'ssh', older versions use 'sshd'
if systemctl cat ssh.service &>/dev/null; then
  SSH_SVC=ssh
else
  SSH_SVC=sshd
fi

# Validate config before restarting so we don't lock
# ourselves out with a broken config.
if sshd -t; then
  systemctl restart "$SSH_SVC"
  echo "   sshd: OK"
else
  echo "   sshd: config test FAILED, rolling back" >&2
  rm -f "$SSHD_DROP"
  exit 1
fi

# ── Weekly reboot timer ───────────────────────────────────

echo ":: Setting up weekly reboot timer..."

cat > /etc/systemd/system/weekly-reboot.service << 'EOF'
[Unit]
Description=Weekly reboot

[Service]
Type=oneshot
ExecStart=/bin/systemctl reboot
EOF

cat > /etc/systemd/system/weekly-reboot.timer << 'EOF'
[Unit]
Description=Weekly reboot

[Timer]
OnCalendar=Sun *-*-* 05:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable weekly-reboot.timer
echo "   weekly-reboot.timer: OK"

# ───────────────────────────────────────────────────────────

echo ""
echo "All done. Summary:"
echo "  - fail2ban:            active (3 retries, 24h ban)"
echo "  - unattended-upgrades: active (daily)"
echo "  - SSH:                 password login disabled"
echo "  - weekly reboot:       Sunday 05:00 UTC"
