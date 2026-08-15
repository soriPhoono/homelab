_: _final: prev: {
  moonlight-qt = prev.moonlight-qt.override {
    ffmpeg = prev.ffmpeg_6;
  };
}
