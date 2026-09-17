# Portable OMP package: load shared plugins, otherwise preserve upstream's
# provider selection, authentication, settings, and onboarding behavior.
{ lib, writeShellApplication, omp, plugins }:
writeShellApplication {
  name = "omp";
  text = ''
    # CLI roots compose with the user's extensions; config arrays replace them.
    exec ${lib.getExe omp} ${lib.concatMapStringsSep " " (plugin: "-e ${lib.escapeShellArg (toString plugin)}") plugins} "$@"
  '';
}
