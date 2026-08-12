{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  rustPlatform,
  cargo,
  rustc,
  pkg-config,
  cmake,
  wrapGAppsHook4,
  webkitgtk_4_1,
  gtk3,
  libsoup_3,
  libayatana-appindicator,
  librsvg,
  alsa-lib,
  opus,
  dbus,
  openssl,
  glib-networking,
  gsettings-desktop-schemas,
  xdg-utils,
  gst_all_1,
}:

let
  pname = "zuno";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "noFAYZ";
    repo = "zuno";
    rev = "v${version}";
    hash = "sha256-K9kUUAHDSiByIezBvamefJ1KIhJPjXJ/yDbr+Tejofk=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    cargoRoot = "src-tauri";
    hash = "sha256-gUq/UWION33Zz8+WLu6He1uvZXKjGoiSqH+9LCeW3Ek=";
  };
in
buildNpmPackage {
  inherit pname version src cargoDeps;
  npmDepsHash = "sha256-nap9cA1si13yn/cSUJOiO5jOoMQj+c5/VXEPEnEfsD0=";
  cargoRoot = "src-tauri";

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo
    rustc
    pkg-config
    cmake
    wrapGAppsHook4
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    libsoup_3
    libayatana-appindicator
    librsvg
    alsa-lib
    opus
    dbus
    openssl
    glib-networking
    gsettings-desktop-schemas
    xdg-utils
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-libav
  ];

  # CMake is used by the Rust opus dependency, not by the project root.
  dontConfigure = true;

  # The upstream release build serves the frontend over localhost because the
  # YouTube IFrame does not initialize under Tauri's custom protocol. Its
  # portpicker probes both IPv4 and IPv6, which is fragile on this host, so
  # keep the localhost route but choose an OS-assigned IPv4 port explicitly.
  postPatch = ''
    substituteInPlace src-tauri/src/lib.rs \
      --replace-fail 'let port = pick_unused_port().expect("failed to find an unused localhost port");' \
        'let port = TcpListener::bind(("127.0.0.1", 0))
          .and_then(|listener| listener.local_addr())
          .map(|address| address.port())
          .expect("failed to find an unused localhost port");' \
      --replace-fail 'format!("http://localhost:{}", port)' \
        'format!("http://127.0.0.1:{}", port)' \
      --replace-fail 'tauri_plugin_localhost::Builder::new(port).build()' \
        'tauri_plugin_localhost::Builder::new(port).host("127.0.0.1").build()'
  '';

  buildPhase = ''
    runHook preBuild

    npm run build

    pushd src-tauri
    cargo build --release --offline
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 src-tauri/target/release/zuno \
      $out/bin/zuno
    install -Dm644 src-tauri/icons/128x128.png \
      $out/share/icons/hicolor/128x128/apps/zuno.png

    install -Dm644 /dev/null $out/share/applications/zuno.desktop
    cat > $out/share/applications/zuno.desktop <<'EOF'
    [Desktop Entry]
    Name=Zuno
    Comment=Zuno - a desktop music client
    Exec=zuno
    Icon=zuno
    StartupWMClass=zuno
    Terminal=false
    Type=Application
    Categories=AudioVideo;Audio;Player;
    EOF

    runHook postInstall
  '';

  # libappindicator-sys loads AppIndicator with dlopen instead of linking it, so
  # the normal ELF dependency scan cannot add this library to the wrapper.
  postInstall = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${libayatana-appindicator}/lib")
  '';

  doCheck = false;

  meta = {
    description = "Desktop YouTube Music client";
    homepage = "https://github.com/noFAYZ/zuno";
    license = lib.licenses.asl20;
    mainProgram = "zuno";
    platforms = [ "x86_64-linux" ];
  };
}
