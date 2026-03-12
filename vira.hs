-- Pipeline configuration for Vira <https://vira.nixos.asia/>

\ctx pipeline ->
  let
    isMain = ctx.branch == "main" || ctx.branch == "mvp1-v2"
  in
  pipeline
    { build.systems = 
        [ "x86_64-linux"
        , "aarch64-darwin"
        ]
    , signoff.enable = True
    , cache.url = if
        | isMain -> Just "https://cache.nixos.asia/oss"
        | otherwise -> Nothing
    }
