#!/usr/bin/env bash
#
# Apply Talos machine configs to nodes
#
# Usage:
#   ./scripts/apply-config.sh [node]
#
# Examples:
#   ./scripts/apply-config.sh           # Apply to all nodes
#   ./scripts/apply-config.sh talos-cp-1  # Apply to specific node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TALOS_DIR="${SCRIPT_DIR}/../talos"
CONFIG_DIR="${TALOS_DIR}/clusterconfig"

# Node configuration
declare -A NODES=(
    ["node1"]="192.168.1.172"
    ["node2"]="192.168.1.173"
    ["node3"]="192.168.1.174"
)

CLUSTER_NAME="talos"

apply_config() {
    local node=$1
    local ip=${NODES[$node]}
    local config_file="${CONFIG_DIR}/${CLUSTER_NAME}-${node}.yaml"

    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file"
        echo "Run 'cd talos && talhelper genconfig' first"
        exit 1
    fi

    echo "Applying config to ${node} (${ip})..."
    talosctl apply-config --insecure \
        --nodes "$ip" \
        --file "$config_file"
    echo "Done: ${node}"
}

main() {
    local target_node=${1:-}

    # Check if configs exist
    if [[ ! -d "$CONFIG_DIR" ]] || [[ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null | grep -v .gitkeep)" ]]; then
        echo "Error: No configs found in ${CONFIG_DIR}"
        echo "Run 'cd talos && talhelper genconfig' first"
        exit 1
    fi

    if [[ -n "$target_node" ]]; then
        # Apply to specific node
        if [[ ! -v "NODES[$target_node]" ]]; then
            echo "Error: Unknown node: $target_node"
            echo "Available nodes: ${!NODES[*]}"
            exit 1
        fi
        apply_config "$target_node"
    else
        # Apply to all nodes
        echo "Applying configs to all nodes..."
        for node in "${!NODES[@]}"; do
            apply_config "$node"
            echo ""
        done
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Wait for nodes to install and reboot"
    echo "  2. Bootstrap cluster: talosctl bootstrap --nodes 192.168.1.172 --talosconfig=${CONFIG_DIR}/talosconfig"
    echo "  3. Get kubeconfig: talosctl kubeconfig --nodes 192.168.1.170 --talosconfig=${CONFIG_DIR}/talosconfig"
}

main "$@"
