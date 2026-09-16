______________________________________________________________________

## name: content-distribution description: "Social media content distribution via Composio — YouTube uploads, Twitter posts, analytics review. Use when uploading videos, posting to socials, or reviewing performance."

# Content Distribution

Distribute video content across platforms using Composio, with human-in-the-loop approval. Read manifests, upload to YouTube, post to Twitter, review analytics.

## Composio

Composio is the bridge to all social media platforms. It handles OAuth authentication and API calls. The `composio` CLI is available on the agent's PATH.

- **YouTube:** Upload videos, set metadata, query analytics (views, watch time, engagement)
- **Twitter/X:** Post text-only content (free tier — no video uploads)
- **Google Analytics:** Read performance data across connected platforms

## Manifest Contract

Read the `video-pipeline-manifest` skill for the full `manifest.json` schema. Key fields for distribution:

- `status`: Must be `"rendered"` or `"ready-to-upload"` before uploading
- `renders[]`: Array of render outputs — use the latest entry's `path` for upload
- `social_copy`: Platform-specific titles, descriptions, tags
- `thumbnail`: Thumbnail image path and generation status
- `upload_status`: Per-platform upload state — update after each attempt

## Platforms & Capabilities

| Platform | Upload Type | Auth Method | Limits | Status |
|---|---|---|---|---|
| YouTube | Full video upload | Composio OAuth | 10K quota/day | ✅ Active |
| Twitter/X | Text + link only | Composio OAuth | Free tier, no video | ✅ Active |
| Instagram | — | — | — | ❌ Removed from scope |
| TikTok | — | — | — | ⏳ WIP (API approval pending) |

## Upload Workflow

### 1. Scan for Ready Renders

Inspect `~/Videos/*/manifest.json` for projects where `status` is `"rendered"` or `"ready-to-upload"`.

### 2. Verify Prerequisites

- Video file exists at `renders[-1].path` and has non-zero size
- `thumbnail.generated` is `true` — if false, leave a note for the human to request thumbnail generation
- `social_copy` fields are populated

### 3. Human-in-the-Loop Approval (MANDATORY)

**Never execute an upload without explicit human approval.**

Present to the human:

- Video title and description
- Tags
- Thumbnail path
- Video file path and size
- Target platform(s)

Wait for explicit confirmation. Only proceed after the human says to upload.

### 4. Upload to YouTube via Composio

```bash
# Upload video with metadata from manifest
composio youtube upload \
  --file ~/Videos/<project>/out/video.mp4 \
  --title "Video Title" \
  --description "Description" \
  --tags "tag1,tag2,tag3" \
  --privacy "public"
```

### 5. Post to Twitter/X

Post text-only content with a link to the YouTube video. Never attempt video uploads to Twitter — the free tier does not support it.

```bash
composio twitter create-tweet \
  --text "New video: Video Title — https://youtube.com/watch?v=VIDEO_ID"
```

### 6. Update Manifest

After upload, update the `upload_status` fields in `manifest.json`:

- `youtube`: `"uploaded"` or `"failed"`
- `twitter`: `"uploaded"`, `"failed"`, or `"skipped"`

### 7. Log in Obsidian

Write a note in the Obsidian vault (via `personal/obsidian` MCP) tagged `#content-distribution` summarizing what was uploaded, with links to the published content.

## Manifest Integrity Rules

**Only modify these fields:**

- `upload_status` — update after each upload attempt
- `social_copy` — may edit with human approval (improving titles, descriptions, tags)
- `notes` — write handoff notes
- `status` — transition `rendered` → `ready-to-upload` → `uploaded`

**Never modify:**

- `renders[]` — the video editor owns render metadata
- `audio` — the video editor owns audio metadata
- `composing` fields

## Analytics Review

### When to Review

The human may ask for analytics review at any time. Use Composio to query YouTube analytics.

### What to Report

| Metric | Source | Value |
|---|---|---|
| Views | YouTube Analytics | Total view count |
| Watch time | YouTube Analytics | Minutes watched |
| Engagement rate | YouTube Analytics | Likes + comments / views |
| Subscriber change | YouTube Analytics | Net new subscribers |

### How to Report

1. Query YouTube analytics via Composio.
1. Compare performance across content topics (programming, NixOS, news, privacy, etc.).
1. Write findings in the Obsidian vault with data-backed recommendations.
1. Analytics inform human decisions — never auto-schedule or auto-delete content based on analytics.

## Pitfalls

- **No autonomous uploads:** Always get human approval before uploading. No exceptions.
- **No Twitter video:** The free tier does not support video uploads. Post text + YouTube link only.
- **Manifest corruption:** Only touch upload-related fields. Never modify render or audio metadata.
- **Rate limits:** YouTube has a 10,000 quota unit/day limit. Large uploads consume significant quota. Queue multiple uploads if needed.
- **Missing thumbnails:** If `thumbnail.generated` is false, do not upload. Request thumbnail generation first.
