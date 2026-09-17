# OMP launcher: compose initialization with portable plugin loading.
# Provider policy belongs to the supplied initialization, not this adapter.
{ lib, writeShellApplication, omp, plugins, initialization }:
writeShellApplication {
  name = "omp";
  text = ''
    ${initialization}

    # CLI roots compose with the user's extensions; config arrays replace them.
    exec ${lib.getExe omp} ${lib.concatMapStringsSep " " (plugin: "-e ${lib.escapeShellArg (toString plugin)}") plugins} "$@"
  '';
}
