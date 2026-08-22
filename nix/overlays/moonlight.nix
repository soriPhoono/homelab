_: _final: prev: {
  moonlight-qt = prev.moonlight-qt.override {
    ffmpeg_8 = prev.ffmpeg_6;
  };
}
