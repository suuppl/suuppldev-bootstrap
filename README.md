# Bootstrap Scripts

Automated server provisioning scripts for setting up a fresh Debian/Ubuntu server to run the Suuppl infrastructure.

## 📥 Installation

Clone the bootstrap scripts repository on your fresh server:

```bash
# Option 1: Clone the dedicated bootstrap repo (recommended)
git clone https://github.com/suuppl/suuppldev-bootstrap.git /opt/bootstrap
cd /opt/bootstrap

# Option 2: Download as archive without git
curl -L https://github.com/suuppl/suuppldev-bootstrap/archive/refs/heads/main.tar.gz | tar xz
cd suuppldev-bootstrap-main
```

## 🚀 Usage

Run the scripts **in order** as root. Each script performs a specific setup task and is safe to re-run.

### 1. Install Development Tools
```bash
sudo ./01-install-tools.sh
```
Installs useful development and debugging tools:
- `git`, `curl`, `wget`, `jq`
- `ncdu`, `tmux`, `btop`
- Build essentials and common utilities

### 2. Install Tailscale
```bash
sudo ./02-install-tailscale.sh
```
Installs and connects Tailscale VPN client:
- Adds Tailscale repository
- Installs `tailscale` package
- Automatically runs `tailscale up` to connect

### 3. Create Docker User
```bash
sudo ./03-create-docker-user.sh
```
Creates a dedicated `docker` user for running rootless Docker:
- Password-disabled (SSH-only access)
- Prompts for SSH public key interactively
- Adds GitHub Actions autodeploy key automatically
- Configures `.ssh/authorized_keys` with proper permissions

### 4. Create Regular User (Optional)
```bash
sudo ./04-create-users.sh
```
Creates a regular user account with sudo access:
- Prompts for username (default: `appuser`)
- Sets password interactively
- Optionally adds SSH public key

### 5. Install Docker
```bash
sudo ./05-install-docker.sh
```
Installs Docker Engine from official repository:
- Adds Docker APT repository
- Installs `docker-ce`, `docker-ce-cli`, `containerd.io`
- Enables and starts Docker service

### 6. Setup Port Forwarding
```bash
sudo ./05-setup-port-forwarding.sh
```
Configures privileged port forwarding (80, 443):
- Sets up `systemd-socket-proxyd` for ports 80 and 443
- Forwards to rootless Docker user namespace
- Enables socket activation

### 7. Configure Rootless Docker
```bash
sudo ./06-configure-rootless.sh
```
Sets up rootless Docker for the docker user:
- Stops and disables system Docker service
- Automatically switches to docker user
- Installs rootless Docker prerequisites
- Configures user namespaces and systemd service
- **Runs as single script with sudo** (no user switching needed)

### 8. Install Doppler
```bash
sudo ./07-install-doppler.sh
```
Installs Doppler CLI for secret management:
- Adds Doppler repository
- Installs `doppler` package
- **Manual step:** Run `doppler login` and `doppler setup` in your project directory

## ⚙️ Complete Setup Example

```bash
# On a fresh Debian/Ubuntu server as root:
cd /root
git clone https://github.com/suuppl/suuppldev-bootstrap.git bootstrap
cd bootstrap

# Run bootstrap sequence in order
./01-install-tools.sh           # Install development tools
./02-install-tailscale.sh       # Install & connect Tailscale
./03-create-docker-user.sh      # Create docker user, paste your SSH pubkey
./04-create-users.sh            # (Optional) Create admin user with password
./05-install-docker.sh          # Install Docker
./05-setup-port-forwarding.sh   # Setup port forwarding for 80/443
./06-configure-rootless.sh      # Configure rootless Docker (auto-switches to docker user)
./07-install-doppler.sh         # Install Doppler CLI

# Then run doppler login and setup as the docker user
su - docker
doppler login
cd /path/to/your/project
doppler setup
```

## 🔒 Security Notes

**SSH Keys:**
- All SSH keys are provided **interactively** at runtime
- **Never commit** private keys or public keys to the repository
- Keys are stored only on the target server in `~/.ssh/authorized_keys`

**Passwords:**
- The docker user has no password (SSH-only access)
- Regular user passwords are set interactively
- Never store passwords in scripts or version control

**Best Practices:**
- Use strong SSH keys (Ed25519 or RSA 4096-bit)
- Disable password authentication in `/etc/ssh/sshd_config` after SSH key setup
- Keep your private keys secure and never share them

## 📋 Prerequisites

- Fresh Debian 11+ or Ubuntu 20.04+ server
- Root access or sudo privileges
- Internet connection
- SSH public key ready (for remote access)

## 🐛 Troubleshooting

**Permission Denied:**
- Ensure scripts are executable: `chmod +x *.sh`
- Run as root: `sudo ./script.sh`

**Rootless Docker Issues:**
- Verify user namespaces: `cat /proc/sys/kernel/unprivileged_userns_clone` should be `1`
- Check systemd service: `systemctl --user status docker` (as docker user)

**Port Forwarding Not Working:**
- Verify socket services: `sudo systemctl status socket-proxy@80.service`
- Check Docker is listening: `ss -tlnp | grep 8080`

## 🔗 Related Documentation

After bootstrapping, proceed to the main infrastructure setup:
- [Main Repository](https://github.com/suuppl/suuppldev)
- [Setup Guide](https://github.com/suuppl/suuppldev/blob/main/docs/setup-guide.md)
- [Service Configuration](https://github.com/suuppl/suuppldev/blob/main/docs/service-configs.md)
