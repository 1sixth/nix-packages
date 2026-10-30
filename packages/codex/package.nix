{
  lib,
  stdenvNoCC,
  fetchurl,

  installShellFiles,
  makeBinaryWrapper,
  nix-update-script,
  ps,
  versionCheckHook,
  zstd,
}:

stdenvNoCC.mkDerivation (
  finalAttrs:
  let
    releases = {
      x86_64-linux = {
        target = "x86_64-unknown-linux-musl";
        hash = "sha256-j3rtxOL4U1dc4VQ0lq/Ir1Fmb3Yo+1NYEO2fagE98b4=";
      };
      aarch64-linux = {
        target = "aarch64-unknown-linux-musl";
        hash = "sha256-QdflZz2GeTlJfC98X4/nZzeVpqgdOjkgOUdWrzIe2gE=";
      };
    };

    sources = lib.mapAttrs (
      _: release:
      fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-package-${release.target}.tar.zst";
        inherit (release) hash;
      }
    ) releases;

    source =
      sources.${stdenvNoCC.hostPlatform.system}
        or (throw "codex: unsupported system ${stdenvNoCC.hostPlatform.system}");
  in
  {
    pname = "codex";
    version = "0.166.0";

    __structuredAttrs = true;

    src = source;

    sourceRoot = ".";

    nativeBuildInputs = [
      installShellFiles
      makeBinaryWrapper
      zstd
    ];

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      rm -r codex-resources/voice

      # Preserve the package layout and real entrypoint for daemon installation.
      mkdir -p $out/libexec/codex
      cp -r bin codex-package.json codex-path codex-resources $out/libexec/codex/

      makeWrapper $out/libexec/codex/bin/codex $out/bin/codex \
        --prefix PATH : ${lib.makeBinPath [ ps ]}
      ln -s ../libexec/codex/bin/codex-code-mode-host $out/bin/codex-code-mode-host

      runHook postInstall
    '';

    postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      installShellCompletion --cmd codex \
        --bash <($out/bin/codex completion bash) \
        --fish <($out/bin/codex completion fish) \
        --zsh <($out/bin/codex completion zsh)
    '';

    doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
    nativeInstallCheckInputs = [ versionCheckHook ];

    passthru = {
      source_x86_64_linux = sources.x86_64-linux;
      source_aarch64_linux = sources.aarch64-linux;

      updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version-regex"
          "^rust-v(.*)$"
          "--no-src"
          "--custom-dep=source_x86_64_linux"
          "--custom-dep=source_aarch64_linux"
        ];
      };
    };

    meta = {
      description = "Lightweight coding agent that runs in your terminal";
      homepage = "https://github.com/openai/codex";
      changelog = "https://github.com/openai/codex/releases/tag/rust-v${finalAttrs.version}";
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      license = lib.licenses.asl20;
      mainProgram = "codex";
      platforms = builtins.attrNames releases;
    };
  }
)
