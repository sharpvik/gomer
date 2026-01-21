port module Main exposing (..)

import Browser exposing (Document)
import Html exposing (Html, button, code, div, nav, pre, text, textarea)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onInput)
import Icon
import Time



-- MODEL


type alias Model =
    { goCode : String
    , goCodeEdited : Bool
    , goOutput : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { goCode = initGoCode
      , goCodeEdited = False
      , goOutput = initGoOutput
      }
    , Cmd.none
    )


initGoCode : String
initGoCode =
    ""


initGoOutput : String
initGoOutput =
    "Program output will appear here"



-- MESSAGES


type Msg
    = EditGoCode String
    | ReceiveGoCode String
    | SendGoCode Time.Posix



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditGoCode text ->
            ( { model | goCode = text, goCodeEdited = True }, Cmd.none )

        ReceiveGoCode code ->
            ( { model | goCode = code }, Cmd.none )

        SendGoCode _ ->
            if model.goCodeEdited then
                ( { model | goCodeEdited = False }, sendGoCode model.goCode )

            else
                ( model, Cmd.none )



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
        [ button [] [ Icon.play ]
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
        , textarea [ class "go-code", value goCode, onInput EditGoCode ] []
        ]


results : String -> Html Msg
results goCode =
    pre [ class "results" ] [ code [] [ text goCode ] ]



-- PORTS


port sendGoCode : String -> Cmd msg


port receiveGoCode : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveGoCode ReceiveGoCode
        , Time.every 1000 SendGoCode
        ]



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
