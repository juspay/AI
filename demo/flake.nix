{
  description = "Demo screencast generator";

  inputs = {
    ai.url = "github:juspay/AI";
    nixpkgs.follows = "ai/nixpkgs";
  };

  outputs = { self, nixpkgs, ai }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      demoDeps = [ pkgs.vhs pkgs.bc ];
    in
    {
      apps.${system}.default = {
        type = "app";
        program = pkgs.lib.getExe (pkgs.writeShellApplication {
          name = "record-demo";
          runtimeInputs = demoDeps;
          text = ''
            tape="''${1:?Usage: record-demo <tape-file>}"
            echo "Recording demo from $tape..."
            vhs "$tape"
            echo "Done!"
          '';
        });
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = demoDeps;
      };
    };
}
