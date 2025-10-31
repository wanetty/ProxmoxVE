#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Eduardo González (wanetty)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wanetty/upgopher

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
msg_ok "Installed Dependencies"

msg_info "Installing Upgopher"
mkdir -p /opt/upgopher
fetch_and_deploy_gh_release "upgopher" "wanetty/upgopher" "singlefile" "latest" "/opt/upgopher" "upgopher*linux*amd64*"
chmod +x /opt/upgopher/upgopher
msg_ok "Installed Upgopher"

msg_info "Configuring Upgopher"

# Prompt for optional authentication
AUTH_FLAGS=""
read -r -p "${TAB3}Enable authentication? (y/N): " enable_auth
if [[ "$enable_auth" =~ ^[Yy]$ ]]; then
  read -r -p "${TAB3}Enter username [admin]: " UPGOPHER_USER
  UPGOPHER_USER=${UPGOPHER_USER:-admin}
  UPGOPHER_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
  {
    echo "Upgopher Credentials"
    echo ""
    echo "Username: $UPGOPHER_USER"
    echo "Password: $UPGOPHER_PASS"
  } >>~/upgopher.creds
  AUTH_FLAGS="-user $UPGOPHER_USER -pass $UPGOPHER_PASS"
  msg_ok "Authentication enabled (credentials saved to ~/upgopher.creds)"
fi

# Prompt for SSL
SSL_FLAG=""
read -r -p "${TAB3}Enable HTTPS with self-signed certificate? (y/N): " enable_ssl
if [[ "$enable_ssl" =~ ^[Yy]$ ]]; then
  SSL_FLAG="-ssl"
  msg_ok "HTTPS enabled"
fi

# Prompt for custom port
read -r -p "${TAB3}Enter port [9090]: " UPGOPHER_PORT
UPGOPHER_PORT=${UPGOPHER_PORT:-9090}

# Prompt for upload directory
read -r -p "${TAB3}Enter upload directory [/opt/upgopher/uploads]: " UPGOPHER_DIR
UPGOPHER_DIR=${UPGOPHER_DIR:-/opt/upgopher/uploads}
mkdir -p "$UPGOPHER_DIR"

# Prompt for hidden files
HIDDEN_FLAG=""
read -r -p "${TAB3}Hide hidden files? (y/N): " hide_hidden
if [[ "$hide_hidden" =~ ^[Yy]$ ]]; then
  HIDDEN_FLAG="-disable-hidden-files"
fi

msg_ok "Configured Upgopher"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/upgopher.service
[Unit]
Description=Upgopher File Server
Documentation=https://github.com/wanetty/upgopher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/upgopher
ExecStart=/opt/upgopher/upgopher -port $UPGOPHER_PORT -dir "$UPGOPHER_DIR" $SSL_FLAG $AUTH_FLAGS $HIDDEN_FLAG
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now upgopher
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
