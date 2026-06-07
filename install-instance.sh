#!/bin/bash
# Xboard-Node Multi-Panel Installer for Debian/Ubuntu
#
# Usage:
#   curl -fsSL URL | sudo bash -s -- --name INSTANCE --panel URL --token TOKEN --machine-id ID
#
# Documentation: https://github.com/lei33440/xboard-node-multi-panel-debian

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="1.0.0"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Check Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    log_error "This script only supports Debian/Ubuntu"
    exit 1
fi

# Parse arguments
INSTANCE_NAME=""
PANEL_URL=""
TOKEN=""
MACHINE_ID=""
INSTALL_VERSION="latest"

while [ $# -gt 0 ]; do
    case "$1" in
        --name) INSTANCE_NAME="$2"; shift 2;;
        --panel) PANEL_URL="$2"; shift 2;;
        --token) TOKEN="$2"; shift 2;;
        --machine-id) MACHINE_ID="$2"; shift 2;;
        --version) INSTALL_VERSION="$2"; shift 2;;
        --help) cat <<'HELP'
Xboard-Node Multi-Panel Installer v1.0.0 (Debian/Ubuntu)

Usage:
  curl -fsSL URL | sudo bash -s -- --name INSTANCE --panel URL --token TOKEN --machine-id ID

Arguments:
  --name NAME       Instance name (required, unique identifier)
  --panel URL       Panel URL (required)
  --token TOKEN     Auth token (required)
  --machine-id ID   Machine ID (required)
  --version VER     Xboard-Node version (default: latest)
  --help            Show this help

Examples:
  # Add first panel
  curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/install-instance.sh | sudo bash -s -- \
    --name mypanel --panel http://panel1.com --token xxx --machine-id 1

  # Add second panel
  curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-multi-panel-debian/main/install-instance.sh | sudo bash -s -- \
    --name backup --panel http://panel2.com --token yyy --machine-id 1

Documentation: https://github.com/lei33440/xboard-node-multi-panel-debian
HELP
exit 0 ;;
        *) shift;;
    esac
done

# Validate arguments
if [ -z "$INSTANCE_NAME" ]; then
    log_error "Missing --name argument"
    exit 1
fi
if [ -z "$PANEL_URL" ]; then
    log_error "Missing --panel argument"
    exit 1
fi
if [ -z "$TOKEN" ]; then
    log_error "Missing --token argument"
    exit 1
fi
if [ -z "$MACHINE_ID" ]; then
    log_error "Missing --machine-id argument"
    exit 1
fi

# Validate instance name (alphanumeric and hyphen only)
if [[ ! "$INSTANCE_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    log_error "Instance name must contain only letters, numbers, and hyphens"
    exit 1
fi

# Paths
SERVICE_NAME="xboard-node-${INSTANCE_NAME}"
CONFIG_DIR="/etc/xboard-node-${INSTANCE_NAME}"
BINARY_PATH="/usr/local/bin/xboard-node"
LOG_DIR="/var/log/xboard-node"

# Banner
echo ""
echo "=============================================="
echo "  Xboard-Node Multi-Panel Installer v${VERSION}"
echo "  (Debian/Ubuntu)"
echo "=============================================="
echo ""
log_info "Instance: ${INSTANCE_NAME}"
log_info "Panel: ${PANEL_URL}"
log_info "Machine ID: ${MACHINE_ID}"
echo ""

# Check if instance already exists
if [ -d "$CONFIG_DIR" ]; then
    log_warn "Instance '${INSTANCE_NAME}' already exists!"
    printf "Do you want to overwrite it? (y/N): "
    read -r confirm
    case "$confirm" in
        y|Y) log_info "Overwriting..." ;;
        *) log_info "Aborted." && exit 0 ;;
    esac
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64|arm64) ARCH_NAME="arm64" ;;
    *) log_error "Unsupported architecture: $ARCH" && exit 1 ;;
esac
log_info "Architecture: $ARCH ($ARCH_NAME)"

# Install dependencies
log_step "Installing dependencies..."
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq curl ca-certificates >/dev/null 2>&1

# Create directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"

# Download binary
if [ ! -f "$BINARY_PATH" ]; then
    log_step "Downloading xboard-node..."
    BASE="https://github.com/cedar2025/xboard-node/releases"
    if [ "$INSTALL_VERSION" = "latest" ]; then
        DOWNLOAD_URL="$BASE/latest/download/xboard-node-linux-$ARCH_NAME"
    else
        DOWNLOAD_URL="$BASE/download/$INSTALL_VERSION/xboard-node-linux-$ARCH_NAME"
    fi
    curl -fsSL -o "$BINARY_PATH" "$DOWNLOAD_URL" || {
        log_error "Failed to download xboard-node"
        exit 1
    }
    chmod +x "$BINARY_PATH"
    log_info "Binary downloaded"
else
    log_info "Binary exists, skipping"
fi

# Create config
log_step "Creating configuration..."
INSTANCE_ID="$(echo "$PANEL_URL" | sed 's|https\?://||' | tr './' '-')-machine-${MACHINE_ID}-$(date +%s)"
cat > "$CONFIG_DIR/config.yml" <<EOF
instances:
    - id: ${INSTANCE_ID}
      panel:
        url: ${PANEL_URL}
      machine:
        machine_id: ${MACHINE_ID}
        token: ${TOKEN}
EOF
log_info "Config: ${CONFIG_DIR}/config.yml"

# Create systemd service
log_step "Creating systemd service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Xboard Node - ${INSTANCE_NAME}
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xboard-node -c ${CONFIG_DIR}/config.yml
Restart=always
RestartSec=5
StandardOutput=append:${LOG_DIR}/${INSTANCE_NAME}.log
StandardError=append:${LOG_DIR}/${INSTANCE_NAME}.log

[Install]
WantedBy=multi-user.target
EOF

# Create unified startup script if first instance
if [ ! -f /usr/local/bin/xboard-node-start-all ]; then
    log_step "Creating startup manager..."
    cat > /usr/local/bin/xboard-node-start-all <<'STRTALL'
#!/bin/bash
# Start all xboard-node instances
for config in /etc/xboard-node-*/config.yml; do
    instance=$(basename $(dirname $config))
    nohup /usr/local/bin/xboard-node -c "$config" >> /var/log/xboard-node/${instance}.log 2>&1 &
    echo "Started $instance"
done
exit 0
STRTALL
    chmod +x /usr/local/bin/xboard-node-start-all
    log_info "Startup manager created"
fi

# Reload systemd
log_step "Reloading systemd..."
systemctl daemon-reload

# Stop existing service if running
log_step "Stopping existing service..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || true
pkill -f "xboard-node.*${CONFIG_DIR}" 2>/dev/null || true

# Enable and start service
log_step "Enabling service..."
systemctl enable "$SERVICE_NAME" 2>/dev/null

log_step "Starting xboard-node..."
systemctl start "$SERVICE_NAME"

# Wait for startup
sleep 3

# Check status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    PORT=$(ss -tlnp 2>/dev/null | grep xboard-node | grep "$CONFIG_DIR" | awk '{print $4}' | cut -d: -f2)

    echo ""
    echo "=============================================="
    log_info "Instance '${INSTANCE_NAME}' installed!"
    echo "=============================================="
    echo ""
    log_info "Config: ${CONFIG_DIR}/config.yml"
    log_info "Log: ${LOG_DIR}/${INSTANCE_NAME}.log"
    [ -n "$PORT" ] && log_info "Port: $PORT"
    echo ""
    log_info "Commands:"
    log_info "  Status:  systemctl status ${SERVICE_NAME}"
    log_info "  Logs:    journalctl -u ${SERVICE_NAME} -f"
    log_info "  Restart: systemctl restart ${SERVICE_NAME}"
    echo ""
else
    echo ""
    log_error "Service failed to start"
    log_error "Check logs: journalctl -u ${SERVICE_NAME} -n 30"
    exit 1
fi