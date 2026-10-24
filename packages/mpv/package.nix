{
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
    version = "0.41.0-unstable-2026-10-23";

    src = fetchFromGitHub {
      owner = "mpv-player";
      repo = "mpv";
      rev = "1140d3cc2974d60b3f8f14fa366ce6dde759f12c";
      hash = "sha256-mB2Qu9EZq2CcMyKOplIV7HZzYgrQMIoT/Ei3KD/o5Uc=";
    };

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
