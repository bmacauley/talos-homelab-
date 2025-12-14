# Talos Homelab Makefile
#
# Usage:
#   make genconfig     Generate Talos machine configs
#   make apply-all     Apply configs to all nodes
#   make bootstrap     Bootstrap the cluster (first node)
#   make kubeconfig    Get kubeconfig from cluster
#   make health        Check cluster health

.PHONY: help setup genconfig gensecret apply-all apply-node-1 apply-node-2 apply-node-3 \
        bootstrap kubeconfig health dashboard services members reset upgrade

# Configuration
CLUSTER_NAME := talos
TALOS_DIR := talos
CONFIG_DIR := $(TALOS_DIR)/clusterconfig
TALOSCONFIG := $(CONFIG_DIR)/talosconfig

# Node IPs
NODE_1 := 192.168.1.172
NODE_2 := 192.168.1.173
NODE_3 := 192.168.1.174
VIP := 192.168.1.170
ALL_NODES := $(NODE_1),$(NODE_2),$(NODE_3)

# Default target
help:
	@echo "Talos Homelab - Available targets:"
	@echo ""
	@echo "  Prerequisites:"
	@echo "    make setup          Install mise tools (talos, talhelper, kubectl)"
	@echo ""
	@echo "  Setup:"
	@echo "    make genconfig      Generate machine configs from talconfig.yaml"
	@echo "    make gensecret      Generate new Talos secrets"
	@echo ""
	@echo "  Provisioning:"
	@echo "    make apply-all      Apply configs to all nodes (insecure mode)"
	@echo "    make apply-node-1   Apply config to node 1 ($(NODE_1))"
	@echo "    make apply-node-2   Apply config to node 2 ($(NODE_2))"
	@echo "    make apply-node-3   Apply config to node 3 ($(NODE_3))"
	@echo "    make bootstrap      Bootstrap etcd on first node"
	@echo "    make kubeconfig     Get kubeconfig from cluster"
	@echo ""
	@echo "  Operations:"
	@echo "    make health         Check cluster health"
	@echo "    make dashboard      Open Talos dashboard (node 1)"
	@echo "    make services       Show services on all nodes"
	@echo "    make members        Show etcd members"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make upgrade        Upgrade Talos on all nodes"
	@echo "    make reset          Reset all nodes (DESTRUCTIVE)"
	@echo ""

# =============================================================================
# Prerequisites
# =============================================================================

setup:
	@echo "Installing mise tools..."
	mise install
	@echo ""
	@echo "Installed tools:"
	@mise list
	@echo ""
	@echo "Run 'mise trust' if prompted to trust the config."

# =============================================================================
# Setup
# =============================================================================

genconfig:
	@echo "Generating Talos configs..."
	cd $(TALOS_DIR) && talhelper genconfig
	@echo "Configs generated in $(CONFIG_DIR)/"

gensecret:
	@echo "Generating new Talos secrets..."
	cd $(TALOS_DIR) && talhelper gensecret > talsecret.yaml
	@echo "Secrets saved to $(TALOS_DIR)/talsecret.yaml"

# =============================================================================
# Provisioning (insecure mode for initial setup)
# =============================================================================

apply-node-1:
	@echo "Applying config to node 1 ($(NODE_1))..."
	talosctl apply-config --insecure \
		--nodes $(NODE_1) \
		--file $(CONFIG_DIR)/talos-node1.yaml

apply-node-2:
	@echo "Applying config to node 2 ($(NODE_2))..."
	talosctl apply-config --insecure \
		--nodes $(NODE_2) \
		--file $(CONFIG_DIR)/talos-node2.yaml

apply-node-3:
	@echo "Applying config to node 3 ($(NODE_3))..."
	talosctl apply-config --insecure \
		--nodes $(NODE_3) \
		--file $(CONFIG_DIR)/talos-node3.yaml

apply-all: apply-node-1 apply-node-2 apply-node-3
	@echo "All configs applied."

bootstrap:
	@echo "Bootstrapping cluster on node 1..."
	talosctl bootstrap \
		--nodes $(NODE_1) \
		--endpoints $(NODE_1) \
		--talosconfig $(TALOSCONFIG)
	@echo "Bootstrap initiated. Wait for cluster to converge."

kubeconfig:
	@echo "Getting kubeconfig..."
	talosctl kubeconfig \
		--nodes $(VIP) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG)
	@echo "Kubeconfig saved to ~/.kube/config"

# =============================================================================
# Operations
# =============================================================================

health:
	@echo "Checking cluster health..."
	talosctl health \
		--nodes $(ALL_NODES) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG)

dashboard:
	@echo "Opening Talos dashboard for node 1..."
	talosctl dashboard \
		--nodes $(NODE_1) \
		--endpoints $(NODE_1) \
		--talosconfig $(TALOSCONFIG)

services:
	@echo "Listing services on all nodes..."
	talosctl services \
		--nodes $(ALL_NODES) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG)

members:
	@echo "Listing etcd members..."
	talosctl etcd members \
		--nodes $(NODE_1) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG)

# =============================================================================
# Maintenance
# =============================================================================

upgrade:
	@echo "Upgrading Talos on all nodes..."
	@echo "Note: Nodes will be upgraded one at a time"
	talosctl upgrade \
		--nodes $(NODE_1) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG) \
		--preserve
	talosctl upgrade \
		--nodes $(NODE_2) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG) \
		--preserve
	talosctl upgrade \
		--nodes $(NODE_3) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG) \
		--preserve

reset:
	@echo "WARNING: This will reset ALL nodes and destroy the cluster!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	talosctl reset --graceful=false --reboot \
		--nodes $(ALL_NODES) \
		--endpoints $(VIP) \
		--talosconfig $(TALOSCONFIG)
