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
            # The tape's first `Output <file>` line, quoted or not.
            out=""
            while IFS= read -r line; do
              case "$line" in
                "Output "*)
                  out="''${line#Output }"
                  out="''${out%\"}"
                  out="''${out#\"}"
                  break
                  ;;
              esac
            done < "$tape"
            echo "Recording demo from $tape..."
            vhs "$tape"
            # vhs can exit 0 having written nothing — seen with vhs 0.12.0,
            # which runs the whole tape, prints "Creating <file>…" and produces
            # no file. Fail here rather than three lines later in `just demo`.
            if [ -n "$out" ] && [ ! -s "$out" ]; then
              echo "Error: vhs exited 0 but wrote no $out." >&2
              exit 1
            fi
            echo "Done!"
          '';
        });
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = demoDeps;
      };
    };
}
