{ fetchFromGitHub, pkgs, version ? "git", ... }:
let
  inherit (pkgs.lib) concatStringsSep;

  gvc = fetchFromGitHub {
    owner = "linkfrg";
    repo = "libgnome-volume-control-wheel";
    rev = "60c21982203cad242938efb6295e535e1c28a10d";
    hash = "sha256-ts7GKD1eXGEx/2/2NBDDx+QhumlydMh8pnQtzpCBGUU=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit version;

  pname = "ignis";

  src = ./..;

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.meson
    pkgs.ninja
    pkgs.git
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.glib
    pkgs.gtk4
    pkgs.gtk4-layer-shell
    pkgs.libpulseaudio
    pkgs.python312Packages.pygobject3
    pkgs.python312Packages.pycairo
    pkgs.python312Packages.click
    pkgs.python312Packages.charset-normalizer
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-plugins-ugly
    pkgs.pipewire
    pkgs.dart-sass
  ];

  patchPhase = ''
    mkdir -p ./subprojects/gvc
    cp -r ${gvc}/* ./subprojects/gvc
    substituteInPlace ignis/utils/sass.py \
      --replace-fail '/bin/sass' '${pkgs.dart-sass}/bin/sass'
  '';

  buildPhase = ''
    cd ..
    meson setup build --prefix=$out
    ninja -C build
  '';

  installPhase = ''
    ninja -C build install
    wrapProgram $out/bin/ignis \
      --prefix-each PATH ":" "${pkgs.gst_all_1.gstreamer}/bin ${pkgs.dart-sass}/bin" \
      --set PYTHONPATH "${concatStringsSep ":" (map (pkg: "${pkg}/lib/python3.12/site-packages") [
        pkgs.python312Packages.markupsafe
        pkgs.python312Packages.pygobject3
        pkgs.python312Packages.pycairo
        pkgs.python312Packages.loguru
        pkgs.python312Packages.certifi
        pkgs.python312Packages.idna
        pkgs.python312Packages.urllib3
        pkgs.python312Packages.requests
        pkgs.python312Packages.click
        pkgs.python312Packages.charset-normalizer
      ])}:$out/lib/python3.12/site-packages:$PYTHONPATH" \
      --set GI_TYPELIB_PATH "$out/lib:${concatStringsSep ":" (map (pkg: "${pkg}/lib/girepository-1.0") [
        pkgs.glib
        pkgs.gobject-introspection
        pkgs.networkmanager
        pkgs.gst_all_1.gstreamer
        pkgs.gnome-bluetooth
      ])}:$GI_TYPELIB_PATH" \
      --set LD_LIBRARY_PATH "$out/lib:${pkgs.gtk4-layer-shell}/lib:${pkgs.glib}/lib:$LD_LIBRARY_PATH" \
      --set GST_PLUGIN_PATH "${concatStringsSep ":" (map (pkg: "${pkg}/lib/gstreamer-1.0") [
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.pipewire
      ])}:$GST_PLUGIN_PATH" \
      --set GDK_PIXBUF_MODULE_FILE "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)"
  '';

  meta = with pkgs.lib; {
    description = "Full-featured Python framework for building desktop shells using GTK4";
    homepage = "https://github.com/linkfrg/ignis";
    changelog = "https://github.com/linkfrg/ignis/releases/tag/v${version}";
    license = licenses.gpl3;
    maintainers = with maintainers; [ frdiener somokill ];
    mainProgram = "ignis";
  };
}
