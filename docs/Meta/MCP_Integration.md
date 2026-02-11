# MCP Integration Guide for The Data Fortress

This guide outlines how to integrate **Model Context Protocol (MCP)** servers to enhance the capabilities of the Gemini CLI agent within this repository.

## Overview

The Model Context Protocol (MCP) allows the Gemini agent to connect to external tools and data sources. Integrating these servers provides the agent with:

- **Deeper Context**: Understanding git history, diffs, and remote repository state.
- **Actionable Tools**: Ability to create GitHub PRs, issues, and fetch external documentation (essential for Nix/NixOS research).

## Recommended Servers

For this Nix-based Homelab environment, we recommend the following set of MCP servers:

### 1. GitHub MCP

- **Purpose**: Manage Issues, Pull Requests, and repository metadata directly from the CLI.
- **Why**: Matches the CI/CD pipeline configuration (`.github/workflows/gemini-review.yml`) and allows the agent to draft PRs for your infrastructure changes.

### 2. Git MCP

- **Purpose**: Read local git history, analyze diffs, and understand file evolution.
- **Why**: Essential for understanding *why* a configuration changed over time, which is critical in infrastructure-as-code (IaC).

### 3. Fetch MCP

- **Purpose**: Retrieve content from the web.
- **Why**: Allows the agent to look up documentation for Nix packages, Home Manager options, and NixOS configuration settings that aren't in the local codebase.

## Configuration Guide

You can configure these servers using the `gemini mcp add` command.

**Prerequisites**:

- `npm` (Node.js) or `docker` installed on your system.
- A GitHub Personal Access Token (PAT) for the GitHub MCP server.

### Option A: Using NPM (Recommended for Local Dev)

Ensure you have `npm` installed (you can add `nodejs` to your `shell.nix` if preferred).

```bash
# 1. GitHub MCP
# Replace YOUR_GITHUB_TOKEN with your actual token
gemini mcp add github npx -y @modelcontextprotocol/server-github
# Note: You will need to set the GITHUB_PERSONAL_ACCESS_TOKEN environment variable in your settings.json
# or pass it inline if supported by your shell environment securely.

# 2. Git MCP
gemini mcp add git npx -y @modelcontextprotocol/server-git

# 3. Fetch MCP
gemini mcp add fetch npx -y @modelcontextprotocol/server-fetch
```

### Option B: Using Docker

If you prefer keeping your host clean or using the same images as CI:

```bash
# 1. GitHub MCP
gemini mcp add github docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token ghcr.io/modelcontextprotocol/servers/github:latest

# 2. Git MCP
# Requires mounting the current directory to work effectively
gemini mcp add git docker run -i --rm -v $(pwd):/projects/repo -w /projects/repo ghcr.io/modelcontextprotocol/servers/git:latest

# 3. Fetch MCP
gemini mcp add fetch docker run -i --rm ghcr.io/modelcontextprotocol/servers/fetch:latest
```

## Post-Installation Check

After adding the servers, verify they are connected:

```bash
gemini mcp list
```

## Agent Workflows

Once configured, you can ask the agent to perform complex tasks:

- **Research**: "Find the NixOS option for configuring a static IP and explain how to apply it to `systems/adams`." (Uses *Fetch*)
- **Audit**: "Check the git history of `secrets.nix` and summarize the last 3 changes." (Uses *Git*)
- **Contribute**: "Create a PR titled 'feat: add new overlay' with the changes I just made." (Uses *GitHub*)
