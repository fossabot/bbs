module View.Post exposing
    ( body
    , btnHead
    , headElement
    , name
    , time
    )

import Env
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Extra exposing (..)
import Url.Builder
import View.Time as Time


name style post =
    let
        htmlTrip =
            if String.isEmpty post.trip then
                nothing

            else
                span [ style.postTrip ] [ text ("!" ++ post.trip) ]

        htmlName =
            span [ style.postName ] [ text <| String.left 32 post.name ]
    in
    headElement style [] [ htmlName, htmlTrip ]


time style zone post =
    headElement style [] [ Time.view zone post.ts ]


body style post =
    div
        [ style.postBody
        , Html.Attributes.style "white-space" "pre-wrap"
        , Html.Attributes.style "word-wrap" "break-word"
        ]
    <|
        List.map (mediaPreview style) post.media
            ++ [ text post.text ]


headElement style attrs =
    div <| [ style.postHeadElement ] ++ attrs


btnHead style btnText =
    headElement style
        []
        [ span [ style.fgButton ] [ text "[" ]
        , span [ style.hypertextLink ] [ text btnText ]
        , span [ style.fgButton ] [ text "]" ]
        ]


mediaPreview style media =
    let
        previewUrl =
            Url.Builder.crossOrigin Env.urlThumb [ media.id ] []
    in
    img [ style.postMediaPreview, src previewUrl ] []
