final: prev: {
  ollama-rocm = prev.ollama-rocm.overrideAttrs (old: rec {
    version = "0.16.0";
    src = prev.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64-rocm.tgz";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  });
}
