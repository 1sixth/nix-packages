{
  lib,
  curl,
  fetchFromGitHub,
  mpv,
  nix-update-script,
  extraMakeWrapperArgs ? [ ],
  youtubeSupport ? true,
  scripts ? [ ],
  extraUmpvWrapperArgs ? [ ],
}:

mpv.override {
  inherit
    extraMakeWrapperArgs
    youtubeSupport
    scripts
    extraUmpvWrapperArgs
    ;

  mpv-unwrapped = mpv.unwrapped.overrideAttrs (oldAttrs: {
    version = "0.41.0-unstable-2026-10-27";

    src = fetchFromGitHub {
      owner = "mpv-player";
      repo = "mpv";
      rev = "82667e3cb116969ec930897a6bf22395e8cd2c36";
      hash = "sha256-VDYGdMs+KKg/u4jrEXKklRIuTWHgEETW30tu19BD13k=";
    };

    buildInputs = oldAttrs.buildInputs ++ [ curl ];
    mesonFlags = oldAttrs.mesonFlags ++ [ (lib.mesonEnable "libcurl" true) ];

    postPatch = ''
      echo "$version" > MPV_VERSION

      substituteInPlace meson.build \
        --replace-fail "conf_data.set_quoted('CONFIGURATION', meson.build_options().strip().replace('\\\\', '\\\\\\\\'))" \
          "conf_data.set_quoted('CONFIGURATION', '<omitted>')"

      pushd TOOLS
      mv mpv_identify.sh mpv_identify
      patchShebangs *.py *.sh
      mv mpv_identify mpv_identify.sh
      popd
    '';

    passthru = oldAttrs.passthru // {
      updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
          "--version-regex=^v?([0-9].*-unstable-.*)$"
        ];
      };
    };
  });
}
