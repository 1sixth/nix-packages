{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "mcp-victoriatraces";
  version = "1.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "VictoriaMetrics";
    repo = "mcp-victoriatraces";
    tag = "v${finalAttrs.version}";
    hash = "sha256-4a8ilOa52n7YwG+bleRsi23ycTNAS5zwU50XTjTa4B0=";
  };

  vendorHash = null;

  env.CGO_ENABLED = 0;

  subPackages = [ "cmd/mcp-victoriatraces/..." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "MCP server for VictoriaTraces";
    homepage = "https://github.com/VictoriaMetrics/mcp-victoriatraces";
    changelog = "https://github.com/VictoriaMetrics/mcp-victoriatraces/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    mainProgram = "mcp-victoriatraces";
  };
})
