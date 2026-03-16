{
  description = "OpenCode demo screencast generator";

  inputs = {
    oc.url = "github:juspay/oc";
    nixpkgs.follows = "oc/nixpkgs";
  };

  outputs = { self, nixpkgs, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      apps.${system}.default = {
        type = "app";
        program = toString (pkgs.writeShellScript "record-demo" ''
          set -euo pipefail
          echo "Recording demo..."
          ${pkgs.vhs}/bin/vhs "${./.}/demo.tape"
          echo "Done! Output: demo.gif"
        '');
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.vhs ];
      };
    };
}
