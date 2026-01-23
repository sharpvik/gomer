port module Main exposing (..)

import Browser exposing (Document)
import Browser.Events exposing (onKeyDown)
import Html exposing (Html, button, code, div, nav, pre, text, textarea)
import Html.Attributes exposing (class, spellcheck, title, value)
import Html.Events exposing (onClick, onInput)
import Http
import Icon
import Json.Decode as Decode
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
    | ReceiveRunResult String
    | SendGoCode Time.Posix
    | RunGoCode
    | RunComplete (Result Http.Error ())
    | FormatGoCode
    | Ignore


type KeyboardEvent
    = Ctrl Char
    | Other



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EditGoCode text ->
            ( { model | goCode = text, goCodeEdited = True }, Cmd.none )

        ReceiveGoCode code ->
            ( { model | goCode = code }, Cmd.none )

        ReceiveRunResult output ->
            ( { model | goOutput = output }, Cmd.none )

        SendGoCode _ ->
            if model.goCodeEdited then
                ( { model | goCodeEdited = False }, sendGoCode model.goCode )

            else
                ( model, Cmd.none )

        RunGoCode ->
            ( { model | goOutput = "Running..." }, runGoCode model.goCode )

        RunComplete _ ->
            ( model, Cmd.none )

        FormatGoCode ->
            ( model, formatGoCode model.goCode )

        Ignore ->
            ( model, Cmd.none )


runGoCode : String -> Cmd Msg
runGoCode goCode =
    Http.post
        { url = "/run"
        , body = Http.stringBody "text/plain" goCode
        , expect = Http.expectWhatever RunComplete
        }


formatGoCode : String -> Cmd Msg
formatGoCode goCode =
    Http.post
        { url = "/format"
        , body = Http.stringBody "text/plain" goCode
        , expect = Http.expectWhatever RunComplete
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
        [ button [ onClick RunGoCode, title "Run code" ] [ Icon.play ]
        , button [ onClick FormatGoCode, title "Format code" ] [ Icon.format ]
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
        , textarea [ class "go-code", value goCode, onInput EditGoCode, spellcheck False ] []
        ]


results : String -> Html Msg
results goCode =
    pre [ class "results" ] [ code [] [ text goCode ] ]



-- PORTS


port sendGoCode : String -> Cmd msg


port receiveGoCode : (String -> msg) -> Sub msg


port receiveRunResult : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveGoCode ReceiveGoCode
        , receiveRunResult ReceiveRunResult
        , onKeyDown (Decode.map toKeyDownMsg eventDecoder)
        , Time.every 500 SendGoCode
        ]


toKeyDownMsg : KeyboardEvent -> Msg
toKeyDownMsg event =
    case event of
        Ctrl 's' ->
            RunGoCode

        Ctrl 'f' ->
            FormatGoCode

        _ ->
            Ignore


eventDecoder : Decode.Decoder KeyboardEvent
eventDecoder =
    Decode.map2
        eventConstructor
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "key" Decode.string)


eventConstructor : Bool -> String -> KeyboardEvent
eventConstructor ctrl key =
    if ctrl then
        specialKeyEvent Ctrl key

    else
        Other


specialKeyEvent : (Char -> KeyboardEvent) -> String -> KeyboardEvent
specialKeyEvent event key =
    case String.uncons key of
        Just ( char, _ ) ->
            event char

        Nothing ->
            Other



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
