-- Pipeline configuration for Vira <https://vira.nixos.asia/>

\ctx pipeline ->
  let
    isMain = ctx.branch == "main"
  in
  pipeline
    { build.systems = 
        [ "x86_64-linux"
        , "aarch64-darwin"
        ]
    , build.flakes =
        [ "."
        , "./doc/demo" { overrideInputs = [("oc", ".")] }
        , "./test/home-manager" { overrideInputs = [("oc", ".")] }
        , "./test/home-manager-with-skills" { overrideInputs = [("oc", ".")] }
        , "./test/standalone" { overrideInputs = [("oc", ".")] }
        ]
    , signoff.enable = True
    , cache.url = if
        | isMain -> Just "https://cache.nixos.asia/oss"
        | otherwise -> Nothing
    }
