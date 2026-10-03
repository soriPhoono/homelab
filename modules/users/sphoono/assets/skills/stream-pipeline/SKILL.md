---
name: stream-pipeline
description: "Orchestrate the stream-to-clips network of skills (video-segmentation, clip-cutting, content-distribution) in sequence on a recording. Use when asked to process, run the pipeline on, or turn a finished stream recording into clips."
---

# Stream Pipeline

Orchestrates the three-skill network for turning a raw stream recording
into distributed clips: `video-segmentation` -> `clip-cutting` ->
`content-distribution`. This skill only **sequences** the other three — it
never performs their work itself, and it never bypasses any of their own
approval gates. Each stage still stops for explicit human approval on its
own terms; this skill just moves to the next stage once a given stage
reports its output is approved.

## Input

A stream-id (or a path), identifying `~/Videos/<stream-id>/source.mp4`.
Confirm the file exists before invoking anything.

## Procedure

### 1. Invoke `video-segmentation`

Hand it the source recording. It will sample frames, propose segment
boundaries, and stop for human approval internally — wait for that to
resolve. Don't pre-approve or second-guess its proposal on its behalf.

If the human rejects the proposal outright (no usable segments), stop the
pipeline here and report that back rather than inventing something to
pass to the next stage.

### 2. Invoke `clip-cutting`

Hand it the approved segment list from step 1 (in-context, no file to
read). It cuts `sections/`, proposes highlight candidates, stops for
approval, renders `clips/`, then stops again for a final review of
everything. Wait for both of its internal gates to resolve before treating
this stage as done.

If no section yields a usable highlight, that's a valid outcome — the
pipeline continues with whatever `sections/`/`clips/` output did get
approved, which may be long-form sections only.

### 3. Hand off to `content-distribution` — currently unavailable

As of this writing, `content-distribution` has not been ported into this
repo and its Composio upload support isn't implemented yet. **Check
whether it's actually registered and working before attempting to invoke
it** — don't assume it exists just because this skill describes it as the
next stage.

Until it is: stop here once step 2's output is approved, and report back
the approved file paths (`sections/*.mp4`, `clips/*.mp4`) so the human can
handle distribution manually. Do not fabricate an upload step or claim
distribution happened.

## Pitfalls

- **This skill approves nothing.** If you find yourself making a judgment
  call about segment boundaries, highlight picks, or upload copy, that
  call belongs to one of the three skills being orchestrated, not to this
  one.
- **No manifest file, same as the rest of the network.** State passes
  between stages through the conversation; don't introduce a file-based
  handoff here either.
- **Don't invoke `content-distribution` speculatively.** If it's not
  there, say so and stop — don't paper over the gap by skipping
  distribution silently or inventing a substitute action.
- **A rejection at any stage ends the run at that stage.** Don't push
  partial or rejected output forward to the next skill.

## Related skills

- `video-segmentation` — stage 1
- `clip-cutting` — stage 2
- `content-distribution` — stage 3, not yet available in this repo (v1
  precedent only, pending a Composio-support port/adaptation)
