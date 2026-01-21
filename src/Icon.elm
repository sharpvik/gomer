module Icon exposing (..)

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)


accentColor : String
accentColor =
    "#0a0a0a"


play : Html msg
play =
    svg [ width "24", height "24", viewBox "0 0 24 24", fill "none" ]
        [ Svg.path [ opacity "0.15", d "M8 6V18L18 12L8 6Z", fill accentColor ] []
        , Svg.path [ d "M8 6V18L18 12L8 6Z", stroke accentColor, strokeWidth "1.5", strokeLinejoin "round" ] []
        ]


format : Html msg
format =
    -- <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    -- <path d="M15 9H13M13.6213 4.37866L11.5 6.49998M9 5V3M6.50004 6.50001L4.37872 4.37869M5 9H3M6.50004 11.5L4.37872 13.6214M9 15V13M20 20L12 12" stroke="#001A72" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    -- </svg>
    svg [ width "24", height "24", viewBox "0 0 24 24", fill "none" ]
        [ Svg.path [ d "M15 9H13M13.6213 4.37866L11.5 6.49998M9 5V3M6.50004 6.50001L4.37872 4.37869M5 9H3M6.50004 11.5L4.37872 13.6214M9 15V13M20 20L12 12", stroke accentColor, strokeWidth "1.5", strokeLinecap "round", strokeLinejoin "round" ] []
        ]
