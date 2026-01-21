module Main exposing (..)

import Browser exposing (Document)
import Html exposing (Html, button, code, div, nav, pre, text, textarea)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)
import Icons



-- MODEL


type alias Model =
    { goCode : String
    , goOutput : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { goCode = initGoCode
      , goOutput = initGoOutput
      }
    , Cmd.none
    )


initGoCode : String
initGoCode =
    """package main

import (
    "fmt"
)

func main() {
    fmt.Println("Hello, World!")
}
"""


initGoOutput : String
initGoOutput =
    "Program output will appear here"



-- MESSAGES


type Msg
    = UpdateText String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateText text ->
            ( { model | goCode = text }, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Gomer"
    , body =
        [ Html.main_ []
            [ navigation
            , editor model.goCode
            , results model.goOutput
            ]
        ]
    }


navigation : Html Msg
navigation =
    nav []
        [ button [] [ Icons.play ]
        ]


editor : String -> Html Msg
editor goCode =
    let
        lineNumbers =
            List.range 0 9999
                |> List.map (\i -> String.fromInt i)
                |> String.join "  \n"
    in
    div [ class "editor" ]
        [ pre [ class "line-numbers" ] [ text lineNumbers ]
        , textarea [ class "go-code", value goCode, onInput UpdateText ] []
        ]


results : String -> Html Msg
results goCode =
    pre [ class "results" ] [ code [] [ text goCode ] ]



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
