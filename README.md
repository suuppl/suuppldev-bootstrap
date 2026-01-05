# Bootstrap Scripts

Automated server provisioning scripts for setting up a fresh Debian/Ubuntu server to run the Suuppl infrastructure.

## 📥 Installation

Clone the bootstrap scripts repository on your fresh server:

```bash
# Option 1: Clone the dedicated bootstrap repo (recommended)
git clone https://github.com/suuppl/suuppldev-bootstrap.git bootstrap
cd bootstrap

# Option 2: Download as archive without git
curl -L https://github.com/suuppl/suuppldev-bootstrap/archive/refs/heads/main.tar.gz | tar xz
cd suuppldev-bootstrap-main
```

## 🚀 Usage

Run the scripts as root. Each script performs a specific setup task and is safe to re-run.

### 0. Prepare Proxmox VE (optional, if running on proxmox)
```bash
./00-prepare-pve.sh
```

Runs the [PVE Post Install Script](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install)

### 1. Install Development Tools
```bash
./01-install-tools.sh
```
Installs useful development and debugging tools:
- `jq` `sudo` `git` `wget` `curl` `unzip` `btop`
- Build essentials and common utilities

### 2. Install Tailscale
```bash
./02-install-tailscale.sh
```
Installs and connects Tailscale VPN client:
- Adds Tailscale repository
- Installs `tailscale` package
- Automatically runs `tailscale up` to connect

### 3. Create Docker User
```bash
./03-create-docker-user.sh
```
## Bootstrap scripts

Small collection of scripts to prepare a fresh Debian/Ubuntu server for running the Suuppl services.

TL;DR:

- `01-install-tools.sh` — Install basic CLI utilities and third-party CLIs (Tailscale, Doppler).
- `02-create-docker-user.sh` — Create a dedicated `docker` user, configure `~/.ssh/authorized_keys`, and manage a GitHub Actions deploy key (can generate one).
- `03-create-users.sh` — Create a regular admin user and add it to `sudo` (interactive).
- `04-install-docker.sh` — Install Docker Engine (convenience script) and add the `docker` user to the `docker` group.

These four scripts are intended to be run (as root) in roughly the order above. They are interactive in places where secrets or SSH keys are required.

Usage examples
```bash
# On a fresh Debian/Ubuntu server as root
git clone https://github.com/suuppl/suuppldev.git /opt/suuppldev
cd /opt/suuppldev/bootstrap

./01-install-tools.sh      # Installs jq, tailscale (via their install script), Doppler CLI, etc.
./02-create-docker-user.sh # Creates `docker` user, sets up ~/.ssh and deploy keys
./03-create-users.sh       # Create an administrative user and add to sudo
./04-install-docker.sh     # Installs Docker and prepares the `docker` group
```

### Script details and notes
- `01-install-tools.sh` — Installs `jq` and other small utilities, then installs Tailscale via `https://tailscale.com/install.sh` and the Doppler CLI via the Doppler apt repository. The script checks for existing installations and will skip if already present. It runs `tailscale up` interactively if not connected and prints Doppler configuration hints.

- `02-create-docker-user.sh` — Creates a `docker` service user (disabled password), ensures `~/.ssh` exists with proper permissions, and prompts for a public SSH key to add to `authorized_keys`. It also prompts for (or generates) a GitHub Actions autodeploy keypair; the public key is appended to `authorized_keys` and the private key is shown for the administrator to store securely (e.g. GitHub Actions secret `DEPLOY_KEY`). Run as root.

- `03-create-users.sh` — Interactive helper to create an administrative user, add them to the `sudo` group, and optionally add an SSH public key to their `~/.ssh/authorized_keys`. Run as root.

- `04-install-docker.sh` — Installs Docker using the official convenience script (`get.docker.com`) if Docker is not already present and adds the `docker` user to the `docker` group. It intentionally leaves further rootless Docker configuration to follow-up steps (not included here).

### Permissions and interactive steps
- All scripts expect to be run as `root` or via `sudo` when interacting with system accounts and installing packages.
- Several scripts prompt interactively for SSH public keys and will not store private keys in the repo. Keep any generated private keys secure and add them to your CI secrets or secret manager.

### Recommended next steps after bootstrapping
- Configure rootless Docker for the `docker` user if you plan to run containers without system Docker (this repo contains notes but not a fully automatic rootless installer).
- Add the generated `DEPLOY_KEY` private key to GitHub repository secrets as `DEPLOY_KEY` for automated deployments.

### Security
- Do not commit private keys or secrets to version control.
- Prefer Ed25519 keys for SSH and rotate deploy keys regularly.
