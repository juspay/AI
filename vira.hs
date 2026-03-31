-- Pipeline configuration for Vira <https://vira.nixos.asia/>

\ctx pipeline ->
  let
    isMain = ctx.branch == "main"
  in
  pipeline
    { build.flakes =
        [ "."
        , "./demo" { overrideInputs = [("oc", ".")] }
        , "./coding-agents/opencode/test/home-manager" { overrideInputs = [("oc", ".")] }
        , "./coding-agents/opencode/test/standalone" { overrideInputs = [("oc", ".")] }
        ]
    , signoff.enable = True
    , cache.url = if
        | isMain -> Just "https://cache.nixos.asia/oss"
        | otherwise -> Nothing
    }
