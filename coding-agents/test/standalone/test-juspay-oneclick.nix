{ ai }:
let
  common = import ./common.nix;
in
{
  name = "opencode-oneclick";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.opencode-juspay-oneclick
    ];
    environment.variables.JUSPAY_API_KEY = "test-api-key";
  };

  testScript = ''
    ${common.testPreamble}
    ${common.opencodeOneclick { expectJuspay = true; }}
  '';
}
