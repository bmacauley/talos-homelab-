# Talos Homelab

## Project Overview

Provision a 3-node Talos Kubernetes cluster on Lenovo M700 mini PCs in a repeatable, Git-driven way.

### Cluster Topology

| Role | Hostname | IP Address |
|------|----------|------------|
| Control Plane 1 | talos-node1 | 192.168.1.172 |
| Control Plane 2 | talos-node2 | 192.168.1.173 |
| Control Plane 3 | talos-node3 | 192.168.1.174 |
| VIP (API endpoint) | - | 192.168.1.170 |

### Design Decisions

- **Stacked control plane**: All 3 nodes run control-plane + etcd
- **VIP on LAN**: Kubernetes API HA via virtual IP (not Tailscale)
- **Tailscale**: Remote access only, via subnet routing
- **talhelper**: Single source of truth for machine configs

---

## Git Workflow

### Branch Naming

Create feature branches from `main`:
- `feat/<feature-name>` - New features
- `fix/<issue-name>` - Bug fixes
- `docs/<topic>` - Documentation changes
- `chore/<task>` - Maintenance tasks

### Commits

- Make incremental, logical commits (one concern per commit)
- Use imperative mood: "Add config" not "Added config"
- Keep first line under 72 characters

**Commit message format:**
```
type(scope): short description

- Longer explanation if needed
- Reference issues: Fixes #123
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`

**Examples:**
```
feat(talos): add talconfig.yaml cluster definition
fix(patches): correct VIP interface binding
docs: update provisioning instructions
chore: add talhelper to mise.toml
```

---

## PR Conventions

### Title
Clear description of what the change does.

### Description
- What the change adds/modifies
- Why it's needed
- How to test/verify the changes

### Guidelines
- One feature per PR
- Keep PRs focused and reviewable
- Ensure all commits are logically organized

---

## Project Structure

```
talos-homelab/
├── CLAUDE.md              # This file
├── README.md              # Project overview
├── mise.toml              # Tool versions (talos, talhelper, etc.)
├── Makefile               # Common commands
├── .gitignore
├── talos/
│   ├── talconfig.yaml     # Cluster definition
│   ├── patches/           # Machine config patches
│   │   ├── controlplane.yaml
│   │   └── tailscale.yaml
│   └── clusterconfig/     # Generated configs (gitignored)
└── scripts/
    └── apply-config.sh    # Helper scripts
```

---

## Quick Reference

### Generate configs
```bash
cd talos && talhelper genconfig
```

### Apply config to node
```bash
talosctl apply-config --insecure --nodes <IP> --file clusterconfig/<node>.yaml
```

### Bootstrap cluster (first node only)
```bash
talosctl bootstrap --nodes 192.168.1.172 --talosconfig=clusterconfig/talosconfig
```

### Get kubeconfig
```bash
talosctl kubeconfig --nodes 192.168.1.170 --talosconfig=clusterconfig/talosconfig
```
