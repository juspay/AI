{ ai }:
let
  common = import ./common.nix;
in
{
  name = "opencode-oneclick-no-juspay";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.opencode-oneclick
    ];
  };

  testScript = ''
    ${common.testPreamble}
    ${common.opencodeOneclick { expectJuspay = false; }}
  '';
}
