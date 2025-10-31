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

# Use default configuration (no authentication, HTTP, default port/directory)
# Users can modify /etc/systemd/system/upgopher.service after installation to enable features
AUTH_FLAGS=""
SSL_FLAG=""
UPGOPHER_PORT="9090"
UPGOPHER_DIR="/opt/upgopher/uploads"
HIDDEN_FLAG=""

mkdir -p "$UPGOPHER_DIR"

msg_ok "Configured Upgopher (default settings: no auth, HTTP, port 9090)"

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
