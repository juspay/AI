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
      lib = pkgs.lib;
    in {
      apps.${system}.default = {
        type = "app";
        program = lib.getExe (pkgs.writeShellApplication {
          name = "record-demo";
          runtimeInputs = [ pkgs.vhs pkgs.bc ];
          text = ''
            echo "Recording demo..."
            vhs "${./.}/demo.tape"
            echo "Done! Output: demo.gif"
          '';
        });
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.vhs pkgs.bc ];
      };
    };
}
