{
  description = "Demo screencast generator";

  inputs = {
    oc.url = "github:juspay/oc";
    nixpkgs.follows = "oc/nixpkgs";
  };

  outputs = { self, nixpkgs, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in {
      apps.${system}.default = {
        type = "app";
        program = lib.getExe (pkgs.writeShellApplication {
          name = "record-demo";
          runtimeInputs = [ pkgs.vhs pkgs.bc ];
          text = ''
            tape="''${1:?Usage: record-demo <tape-file>}"
            echo "Recording demo from $tape..."
            vhs "$tape"
            echo "Done!"
          '';
        });
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.vhs pkgs.bc ];
      };
    };
}
