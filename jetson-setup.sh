# Allow sudo without password
currentUser=$(whoami)
sudo tee -a /etc/sudoers.d/1-jetson > /dev/null <<EOF
$currentUser ALL=(ALL) NOPASSWD: ALL
EOF

# Update packages and dependencies
sudo apt-get update -yq
sudo apt-get upgrade -yq

# Install the VNC Server
sudo apt-get update -yq
sudo apt-get install -yq vino

# Cleanup
sudo apt-get autoremove -yq
sudo apt-get autoclean -yq

# Enable the VNC server to start each time you log in
mkdir -p ~/.config/autostart
cp /usr/share/applications/vino-server.desktop ~/.config/autostart

# Configure the VNC server
gsettings set org.gnome.Vino prompt-enabled false
gsettings set org.gnome.Vino require-encryption false

# Set a password to access the VNC server
gsettings set org.gnome.Vino authentication-methods "['vnc']"
gsettings set org.gnome.Vino vnc-password $(echo -n '123456?a'|base64)

# Install AdGuard Home
sudo snap install adguard-home
