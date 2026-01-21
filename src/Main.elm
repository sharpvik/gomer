port module Main exposing (..)

import Browser exposing (Document)
import Html exposing (Html, button, code, div, nav, pre, text, textarea)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)
import Http
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
    | RunGoCode
    | ReceiveRunResult (Result Http.Error String)



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

        RunGoCode ->
            ( model, runGoCode model.goCode )

        ReceiveRunResult (Ok output) ->
            ( { model | goOutput = output }, Cmd.none )

        ReceiveRunResult (Err _) ->
            ( { model | goOutput = "Error running code" }, Cmd.none )


runGoCode : String -> Cmd Msg
runGoCode goCode =
    Http.post
        { url = "http://localhost:8080/run"
        , body = Http.stringBody "text/plain" goCode
        , expect = Http.expectString ReceiveRunResult
        }



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
        [ button [ onClick RunGoCode ] [ Icon.play ]
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
        , Time.every 500 SendGoCode
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
