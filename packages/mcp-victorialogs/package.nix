{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchNpmDeps,
  nix-update-script,
  nodejs,
  npmHooks,
}:

buildGoModule (finalAttrs: {
  pname = "mcp-victorialogs";
  version = "1.11.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "VictoriaMetrics";
    repo = "mcp-victorialogs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-F61g7Br7sR8b9Bbi/ZBbBE3ZfeogXyY5lxpa/0ayHFI=";
  };

  vendorHash = null;

  env.CGO_ENABLED = 0;

  subPackages = [ "cmd/mcp-victorialogs/..." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  npmDeps = fetchNpmDeps {
    name = "mcp-victorialogs-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/web";
    hash = "sha256-I5SdSq6O0DYuLHoREeSoA5q4GYh4iwOY9XvhQPfEDRU=";
  };

  npmRoot = "web";

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  preBuild = ''
    npm --prefix web run build
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "MCP server for VictoriaLogs";
    homepage = "https://github.com/VictoriaMetrics/mcp-victorialogs";
    changelog = "https://github.com/VictoriaMetrics/mcp-victorialogs/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    mainProgram = "mcp-victorialogs";
  };
})
