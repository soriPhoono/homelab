______________________________________________________________________

## name: video-pipeline-manifest description: Shared manifest contract for the video pipeline. Use when creating, reading, or updating video project manifests for inter-agent handoff.

# Video Pipeline Manifest

This skill defines the manifest format used by the video pipeline agents to coordinate video production, rendering, and social media uploads.

## Manifest Location

Each video project lives in `~/Videos/<project-name>/`. The manifest file is `manifest.json` at the project root:

```
~/Videos/<project-name>/
├── manifest.json          # The manifest (this skill defines its schema)
├── src/                   # Remotion source code
├── out/                   # Rendered output files
│   ├── video.mp4
│   └── thumbnail.png
└── audio/                 # Audio assets (Strudel exports, Starsinger tracks)
```

## Manifest Schema

```json
{
  "title": "NixOS Flakes Explained",
  "topic": "programming",
  "template": "code-walkthrough",
  "description": "A tutorial explaining NixOS flake basics",
  "status": "rendered",
  "created_at": "2026-08-22T14:00:00Z",
  "updated_at": "2026-08-22T14:30:00Z",
  "duration_seconds": 287,
  "renders": [
    {
      "path": "out/video.mp4",
      "resolution": "1920x1080",
      "fps": 30,
      "frame_count": 8610,
      "rendered_at": "2026-08-22T14:30:00Z",
      "file_size_bytes": 45000000
    }
  ],
  "audio": {
    "type": "strudel|starsinger|none",
    "path": "audio/track.mp3",
    "bpm": 120,
    "duration_seconds": 287,
    "license": "CC0"
  },
  "social_copy": {
    "youtube": {
      "title": "NixOS Flakes Explained — Declarative Reproducible Systems",
      "description": "Full description text...",
      "tags": ["nixos", "nix", "linux", "declarative"]
    },
    "twitter": {
      "text": "New video: NixOS Flakes Explained 🧵"
    }
  },
  "thumbnail": {
    "path": "out/thumbnail.png",
    "dimensions": "1280x720",
    "generated": false
  },
  "upload_status": {
    "youtube": "pending|uploaded|failed",
    "twitter": "pending|uploaded|failed|skipped"
  },
  "notes": "Optional freeform notes for inter-agent communication"
}
```

## Field Reference

### Top-level fields

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | string | ✅ | Human-readable video title |
| `topic` | string | ✅ | Content category: `programming`, `linux`, `nixos`, `hardware`, `politics`, `privacy`, `news`, `computer-science` |
| `template` | string | ✅ | Remotion template used: `code-walkthrough`, `news-roundup`, `tech-explainer`, `privacy-deep-dive`, `hardware-review` |
| `description` | string | ❌ | One-line description of the video content |
| `status` | enum | ✅ | `planning`, `scripted`, `composing`, `rendering`, `rendered`, `ready-to-upload`, `uploaded` |
| `created_at` | ISO 8601 | ✅ | When the project was created |
| `updated_at` | ISO 8601 | ✅ | When the manifest was last updated |
| `duration_seconds` | number | ❌ | Final video duration in seconds (filled after render) |

### renders[]

Array of render outputs. Append new renders; do not delete old ones.

| Field | Type | Description |
|---|---|---|
| `path` | string | Relative path from project root to the rendered file |
| `resolution` | string | e.g. `1920x1080` |
| `fps` | number | Frames per second |
| `frame_count` | number | Total frames rendered |
| `rendered_at` | ISO 8601 | When this render completed |
| `file_size_bytes` | number | File size in bytes |

### audio

Audio track metadata.

| Field | Type | Description |
|---|---|---|
| `type` | enum | `strudel` (custom synthesis), `starsinger` (sourced track), `none` |
| `path` | string | Relative path to audio file |
| `bpm` | number | Beats per minute (for timing sync) |
| `duration_seconds` | number | Audio duration |
| `license` | string | License type (must be CC0 or public domain) |

### social_copy

Platform-specific upload metadata. The social media agent reads this to perform uploads.

| Platform | Fields | Notes |
|---|---|---|
| `youtube` | `title`, `description`, `tags` | YouTube Data API v3 upload |
| `twitter` | `text` | Text-only post (free tier, no video upload) |

### thumbnail

| Field | Type | Description |
|---|---|---|
| `path` | string | Relative path to thumbnail image |
| `dimensions` | string | e.g. `1280x720` for YouTube |
| `generated` | boolean | Whether the thumbnail has been generated |

### upload_status

Tracks upload state per platform. Updated by the social media agent after upload attempts.

| Platform | Values |
|---|---|
| `youtube` | `pending` → `uploaded` / `failed` |
| `twitter` | `pending` → `uploaded` / `failed` / `skipped` |

### notes

Freeform text field for inter-agent communication. Use this to leave instructions or context for the other agent (e.g., "render a 15-second clip for Twitter from 2:30-2:45").

## Agent Responsibilities

### Video Editor Agent

1. Creates `manifest.json` when starting a new project with `status: "planning"`
1. Updates `status` as work progresses: `planning` → `scripted` → `composing` → `rendering` → `rendered`
1. Appends render entries to `renders[]` after each successful render
1. Fills `audio` metadata when audio is added
1. Sets `thumbnail.generated` when thumbnail is created
1. Writes `social_copy` suggestions (the social media agent may edit these)
1. Leaves notes for the social media agent in `notes`

### Social Media Agent (Default Profile)

1. Scans `~/Videos/*/manifest.json` for projects with `status: "rendered"` or `"ready-to-upload"`
1. Reads `social_copy` for upload metadata
1. Checks `thumbnail.generated` — if false, requests thumbnail generation first
1. Performs uploads via Composio (YouTube) or direct API
1. Updates `upload_status` fields after upload attempts
1. May edit `social_copy` fields (improving titles, descriptions, tags)
1. Reads `notes` for special instructions from the video editor
1. May request video snippets by adding a note for the human to relay to the video editor

### Human (sphoono)

1. Relays between agents (tells video editor to make a snippet, tells social media agent a render is ready)
1. Approves uploads before the social media agent executes them
1. Reviews and edits `social_copy` if desired
1. Triggers renders via SSH: `ssh desktop-ares "hermes profile use video-editor && hermes chat -q '...'"`

## Status Flow

```
planning → scripted → composing → rendering → rendered → ready-to-upload → uploaded
                                                              ↑
                                                    social media agent picks up
```

## Inter-Agent Handoff Protocol

1. **Video editor finishes a render:** Updates `status` to `rendered`, fills `renders[]`, writes `social_copy` suggestions, leaves a `note` for the social media agent.
1. **Human relays:** "Hey social media agent, video X is ready, check the manifest."
1. **Social media agent reads manifest:** Verifies `status: "rendered"`, checks `thumbnail.generated`, reviews `social_copy`.
1. **Thumbnail generation (if needed):** Human invokes the thumbnail skill (or asks the video editor to generate one).
1. **Upload:** Social media agent uploads to YouTube via Composio, posts text to Twitter. Updates `upload_status`.
1. **Analytics feedback:** Social media agent checks analytics via Composio and recommends content direction changes in the Obsidian vault.
