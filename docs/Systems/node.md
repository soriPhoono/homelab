# Node

`node` is a specialized "sidecar" system within the homelab environment.

## 🏗️ Role & Purpose

Unlike the primary Talos Linux cluster, `node` acts as a simple, standalone Docker runtime. It serves as a **Template for Systems**, allowing for rapid deployment of specialized Docker environments.

## 🚀 Key Features

- **Modular Runtime**: Easily adaptable with different `docker-compose` configurations.
- **Sidecar Services**: Hosts auxiliary services like Pi-hole and other non-cluster utilities.
- **Lightweight**: Minimal core setup focused on container execution.
