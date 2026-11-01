# ComfyUI on AMD ROCm for desktop-ares (RX 7900 XTX, gfx1100).
#
# The base image ships a ROCm build of PyTorch, so ComfyUI's own torch pins
# are dropped before installing its requirements; reinstalling torch from
# PyPI would replace the ROCm build with a CPU or CUDA one.
ARG ROCM_PYTORCH_TAG=rocm10.1.0_ubuntu24.04_py3.12_pytorch_release_2.14.0
ARG COMFYUI_VERSION=0.43.2

FROM rocm/pytorch:${ROCM_PYTORCH_TAG}
ARG COMFYUI_VERSION

# The base image has no git, curl or `python` (only `python3`, with ROCm torch
# in the system site-packages), so the release tarball comes down with
# the Python it already ships.
RUN mkdir /opt/ComfyUI \
  && python3 -c "import urllib.request as u; u.urlretrieve('https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/v${COMFYUI_VERSION}.tar.gz', '/tmp/comfyui.tar.gz')" \
  && tar -xzf /tmp/comfyui.tar.gz -C /opt/ComfyUI --strip-components=1 \
  && rm /tmp/comfyui.tar.gz \
  && grep -viE '^(torch|torchvision|torchaudio)([<>=!~ ]|$)' \
      /opt/ComfyUI/requirements.txt > /tmp/requirements.txt \
  && python3 -m pip install --no-cache-dir -r /tmp/requirements.txt \
  && rm /tmp/requirements.txt

WORKDIR /opt/ComfyUI
# Models, custom nodes, inputs and outputs live in the mounted /data volume;
# HOME points there too so the non-root runtime user has somewhere to write.
ENV HOME=/data
EXPOSE 8188
ENTRYPOINT ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--base-directory", "/data"]
