---
name: clip-cutting
description: "Render approved segments into source-aspect section clips, then find and crop short vertical highlights for Shorts/TikTok/Reels within them. Use after video-segmentation has an approved segment list, before content-distribution."
---

# Clip Cutting

Second stage of the stream-to-clips pipeline (after `video-segmentation`,
before `content-distribution`). Takes the human-approved segment list
handed off in-context from `video-segmentation` and produces two kinds of
output: full-length section clips at the source aspect ratio, and short
vertical highlight crops carved out of those sections for
Shorts/TikTok/Reels.

## Input

The approved segment list from `video-segmentation` (start/end timestamps,
topic, justification), carried forward in the conversation — there is no
file to read it from. Also `~/Videos/<stream-id>/source.mp4`, the original
recording.

## Procedure

### 1. Cut each approved segment into a section clip

Boundaries were already approved in `video-segmentation`'s gate, so this
step is mechanical — no new judgment, no new approval needed here
specifically (it's still covered by this skill's final review in step 4).

```bash
mkdir -p ~/Videos/<stream-id>/sections
ffmpeg -ss <start> -to <end> -i ~/Videos/<stream-id>/source.mp4 -c copy \
  ~/Videos/<stream-id>/sections/<segment-id>.mp4
```

Stream-copy (`-c copy`) is fast and lossless, but snaps to the nearest
keyframe, so a section's actual boundary can drift a second or two from
the approved timestamp. Acceptable here — these boundaries came from
coarse sampling in `video-segmentation` to begin with. These section clips
are themselves candidates for long-form upload (e.g. as a regular YouTube
video), not just scratch material for the next step.

### 2. Find short, self-contained highlights within each section

Sections are "about one topic," not "one punchy moment" — a Short needs
the latter. Sample frames within each section at a finer interval than
`video-segmentation` used (sections are much shorter than the full
recording):

```bash
mkdir -p ~/Videos/<stream-id>/frames/<segment-id>
ffmpeg -i ~/Videos/<stream-id>/sections/<segment-id>.mp4 -vf "fps=1/3" \
  -q:v 2 ~/Videos/<stream-id>/frames/<segment-id>/%06d.jpg
```

Look for a self-contained moment that stands on its own without the
surrounding context: a joke, a breakthrough ("it finally works"), a clutch
play, a concise insight — something roughly 15-60 seconds long with a
clear hook. A section may yield zero, one, or several highlight
candidates; don't force one out of a section that doesn't have one.

Propose each candidate with its timestamp range and the reason it works as
a standalone moment.

### 3. Stop for approval before rendering highlights — mandatory

**Never crop a highlight candidate before it's approved.** Vertical
rendering is wasted work on a bad pick, same reasoning as
`video-segmentation`'s gate. Present the candidates and wait for explicit
approval, rejection, or timestamp adjustment.

### 4. Render approved highlights as vertical clips

```bash
mkdir -p ~/Videos/<stream-id>/clips
ffmpeg -ss <start> -to <end> -i ~/Videos/<stream-id>/sections/<segment-id>.mp4 \
  -vf "crop=ih*9/16:ih" -c:v libx264 -c:a aac \
  ~/Videos/<stream-id>/clips/<segment-id>-short-<n>.mp4
```

Re-encoding (not stream-copy) here is deliberate: these are short,
hook-driven clips where the exact start matters far more than it did for
the coarse section cuts.

`crop=ih*9/16:ih` is a **naive center crop** — it has no idea where the
speaker, the code, or the gameplay action actually is in frame. It can cut
off exactly the thing that made the moment worth clipping. Flag this
plainly when presenting the result in the next step; don't present a
center-cropped clip as if the framing were verified.

### 5. Present everything for final approval — mandatory

Present both outputs together, not separately:

- `sections/*.mp4` — full-length, source-aspect clips (long-form
  candidates)
- `clips/*.mp4` — vertical highlight crops (Shorts/TikTok/Reels
  candidates)

Never hand anything to `content-distribution` that hasn't been explicitly
approved here. Delete or otherwise exclude rejected files rather than
leaving them for the next skill to stumble into.

## Pitfalls

- **No manifest file.** The approved segment list arrived in-context from
  `video-segmentation`; this skill's own output (which sections/clips are
  approved) likewise hands off in-context to `content-distribution`, not
  through a written file.
- **Don't skip the step-3 gate.** Proposing highlight candidates is not
  the same as having permission to crop them.
- **Don't present a center crop as correct.** It's a starting point, not a
  verified framing — say so when asking for approval in step 5.
- **A section without a good highlight is a valid outcome.** Don't
  manufacture a weak Short just to produce one from every section.

## Related skills

- `video-segmentation` — previous stage, supplies the approved segment
  list
- `content-distribution` — next stage (v1 skill, needs adapting: it
  currently scans `~/Videos/*/manifest.json` for `status: rendered` — that
  trigger is gone, it should instead take the approved file lists from
  both `sections/` and `clips/` directly)
