{ config, pkgs, lib, ... }:

let
  kimi-code = pkgs.stdenv.mkDerivation rec {
    pname = "kimi-code";
    version = "0.28.1";

    src = pkgs.fetchurl {
      url = "https://code.kimi.com/kimi-code/binaries/${version}/kimi-code-linux-x64";
      sha256 = "8a2e0baa2e8654d5320eaee25fd3f0db0ccfc3d520595c5a273bacb9cdd95a33";
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      pkgs.ripgrep
      pkgs.fd
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/kimi"
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/kimi --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';

    meta = {
      description = "Kimi Code CLI — AI coding agent from Moonshot AI";
      homepage = "https://github.com/MoonshotAI/kimi-code";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "kimi";
    };
  };
in
{
  home.packages = [ kimi-code ];
}
