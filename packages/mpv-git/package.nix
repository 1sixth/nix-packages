{
  fetchFromGitHub,
  mpv,
  nix-update-script,
}:

mpv.override {
  mpv-unwrapped = mpv.unwrapped.overrideAttrs (oldAttrs: {
    version = "0.41.0-unstable-2026-10-22";

    src = fetchFromGitHub {
      owner = "mpv-player";
      repo = "mpv";
      rev = "fa0534a729dd3dff33ea03cc7c226d317a4fcd07";
      hash = "sha256-CIuS6ovUwI2KXyGDcIE3Tu+tcEnJclvNgK5Fix/Oc18=";
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
