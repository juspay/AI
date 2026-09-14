{ pkgs, lib, omp, modelsFile }:
let
  piLib = import ../pi/lib.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "omp";
  meta.description = "Oh My Pi with editable Juspay model configuration";
  text = ''
    ${piLib.ensureApiKey}
    # Let OMP resolve its own config root, environment overrides and profile.
    agent_dir=$(${lib.getExe omp} config path)
    # Respect both YAML spellings and OMP's legacy JSON migration path.
    if [ ! -e "$agent_dir/models.yml" ] && [ ! -e "$agent_dir/models.yaml" ] && [ ! -e "$agent_dir/models.json" ]; then
      mkdir -p "$agent_dir"
      cp ${modelsFile} "$agent_dir/models.yml"
      chmod u+w "$agent_dir/models.yml"
    fi
    exec ${lib.getExe omp} "$@"
  '';
}
