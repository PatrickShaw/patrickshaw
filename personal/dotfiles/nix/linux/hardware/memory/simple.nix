{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 40;
    memoryMax = 16000000000; # 16 GB
  };
}
