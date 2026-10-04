# n8n task runners with ffmpeg, so Python Code nodes and Code Tools can
# render video for the content pipeline.
#
# The runners image ships without a package manager, so ffmpeg comes in as
# static binaries and the runner config is patched in a throwaway stage.
ARG N8N_VERSION=2.39.6
ARG FFMPEG_VERSION=9.0.2

FROM mwader/static-ffmpeg:${FFMPEG_VERSION} AS ffmpeg

FROM n8nio/runners:${N8N_VERSION} AS runners

FROM alpine:3.22 AS config
# Stdlib modules the Python runner may import. Upstream allows none; the
# render code shells out to ffmpeg and manages files under /data/vods.
ARG PYTHON_STDLIB_ALLOW=subprocess,json,pathlib,tempfile,shutil,os,re,datetime
# hadolint ignore=DL3018
RUN apk add --no-cache jq
COPY --from=runners /etc/n8n-task-runners.json /tmp/upstream.json
RUN jq --arg allow "${PYTHON_STDLIB_ALLOW}" \
    '(."task-runners"[] | select(."runner-type" == "python") | ."env-overrides".N8N_RUNNERS_STDLIB_ALLOW) = $allow' \
    /tmp/upstream.json > /tmp/n8n-task-runners.json

FROM runners
COPY --from=ffmpeg /ffmpeg /ffprobe /usr/local/bin/
COPY --from=config /tmp/n8n-task-runners.json /etc/n8n-task-runners.json
