---
name: video-segmentation
description: "Judge topic/segment boundaries in a raw stream recording by visually inspecting sampled frames, and propose a segment list for human approval. Use when a new stream recording needs to be cut into segments for clipping, before any rendering happens."
---

# Video Segmentation

First stage of the stream-to-clips pipeline (part of a three-skill network
with `clip-cutting` and `content-distribution`, invoked in sequence by a
human or by the `stream-pipeline` orchestrating skill). This skill never
renders video — it only proposes _where_ to cut, from visual inspection, and
stops for human approval before handing off.

The source content is coding/gaming commentary streams. Topic shifts in this
content are not reliably verbal — long silent debugging stretches,
gameplay-only segments — so boundaries are judged from the video itself, not
a transcript.

## Input

A path to a source recording, conventionally `~/Videos/<stream-id>/source.mp4`
(this file is also the local VOD backup, mirrored to NAS — don't move or
delete it).

## Procedure

### 1. Sample frames

Extract frames at a fixed interval into a scratch directory next to the
source:

```bash
mkdir -p ~/Videos/<stream-id>/frames
ffmpeg -i ~/Videos/<stream-id>/source.mp4 -vf "fps=1/15" -q:v 2 \
  ~/Videos/<stream-id>/frames/%06d.jpg
```

`fps=1/15` samples one frame every 15 seconds — a starting default, not a
fixed rule. Frame _N_ (1-indexed) corresponds to timestamp `(N - 1) * 15`
seconds. Tighten the interval (e.g. `fps=1/5`) around a timestamp range if
the 15-second sampling leaves a suspected boundary ambiguous — re-sample
that range only, don't re-sample the whole recording at fine granularity by
default; a multi-hour stream at a short interval is a lot of frames to
inspect.

### 2. Inspect frames in order, judge boundaries

Walk the sampled frames in timestamp order. Look for:

- Editor/IDE context changing (different file, different project,
  switching from coding to running/debugging)
- Game state changing significantly (new level, new match, switching games
  entirely)
- Explicit scene transitions (webcam-only break, alt-tab to browser/chat
  for an extended stretch)

For each candidate boundary, note the **visual basis** — what actually
changed in the frames that justifies the cut. This justification travels
with the proposal in the next step; don't propose a boundary you can't
point to a concrete visual change for.

Avoid over-segmenting. A boundary needs a real topic/context change, not
just "the sampled frame looks a bit different" — err toward fewer, longer
segments over many tiny ones; the human reviewing the list in the next step
can always ask for a segment to be split further.

### 3. Propose the segment list

Present the proposed segments to the human, each with:

- Start/end timestamp
- A short topic label (what this segment is actually about)
- The visual basis for both the start and end cut

### 4. Stop for approval — mandatory

**Never proceed to cutting.** This skill's job ends at the proposed list.
Present it and explicitly ask the human to approve, reject, or edit
(merge/split/adjust timestamps) before considering the stage done. The
approved list — not the proposal — is what gets handed off to
`clip-cutting` next, carried forward in the conversation; there is no
manifest file to write.

## Pitfalls

- **No manifest file.** State moves through the conversation to the next
  skill invocation, not a written contract. Don't invent a `segments.json`
  as a side effect — that was the earlier (abandoned) design.
- **Don't skip the approval gate.** Proposing a list is not the same as
  finishing the job — an unapproved proposal is not ready for
  `clip-cutting`.
- **Don't over-sample by default.** Fine-grained sampling across an entire
  multi-hour recording is expensive; sample coarse first, then narrow only
  where a boundary is genuinely ambiguous.
- **Don't touch `source.mp4`.** This skill only reads it and writes to
  `frames/`; it's also the VOD backup.
