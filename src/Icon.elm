module Icon exposing (..)

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)


play : Html msg
play =
    let
        hexColor =
            "#0a0a0a"
    in
    svg [ width "24", height "24", viewBox "0 0 24 24", fill "none" ]
        [ Svg.path [ opacity "0.15", d "M8 6V18L18 12L8 6Z", fill hexColor ] []
        , Svg.path [ d "M8 6V18L18 12L8 6Z", stroke hexColor, strokeWidth "1.5", strokeLinejoin "round" ] []
        ]
