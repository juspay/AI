{ pkgs, lib, omp, modelsFile }:
let
  wrapper = import ../wrapper.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "omp";
  meta.description = "Oh My Pi with editable Juspay model configuration";
  text = ''
    ${wrapper.ensureApiKey}
    # Let OMP resolve its own config root, environment overrides and profile.
    agent_dir=$(${lib.getExe omp} config path)
    ${wrapper.seedConfigFile {
      src = modelsFile;
      dir = "$agent_dir";
      name = "models.yml";
      # Respect both YAML spellings and OMP's legacy JSON migration path.
      existing = [ "$agent_dir/models.yml" "$agent_dir/models.yaml" "$agent_dir/models.json" ];
    }}
    exec ${lib.getExe omp} "$@"
  '';
}
