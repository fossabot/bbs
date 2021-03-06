module Post exposing
    ( EventHandlers
    , EventHandlersOP
    , No
    , Op
    , Post
    , decoder
    , mapMedia
    , opDomID
    , toggleMediaPreview
    , view
    , viewOp
    )

import Config exposing (Config)
import Env
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Extra exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DecodeExt
import List.Extra
import Media exposing (Media)
import Route
import String.Extra
import Tachyons exposing (classes)
import Tachyons.Classes as T
import Tachyons.Classes.Extra as TE
import Theme exposing (Theme)
import Time exposing (Month(..), Zone)
import Url.Builder


type alias Post =
    { no : No
    , name : String
    , trip : String
    , text : String
    , ts : Int
    , media : List Media
    }


type alias Op =
    { threadID : ThreadID
    , subject : Maybe String
    , post : Post
    }


type alias No =
    Int


type alias EventHandlers msg a =
    { a
        | onMediaClicked : ThreadID -> No -> Media.ID -> msg
        , onReplyToClicked : ThreadID -> No -> msg
    }


type alias EventHandlersOP msg =
    EventHandlers msg
        { onNextThreadClicked : Maybe (ThreadID -> msg)
        , onPrevThreadClicked : Maybe (ThreadID -> msg)
        }


type alias ThreadID =
    Int


mapMedia : Media.ID -> (Media -> Media) -> Post -> Post
mapMedia mediaID f post =
    { post | media = List.Extra.updateIf (.id >> (==) mediaID) f post.media }


toggleMediaPreview : Media.ID -> Post -> Post
toggleMediaPreview mediaID =
    mapMedia mediaID Media.togglePreview


decoder : Decoder Post
decoder =
    Decode.map6 Post
        (Decode.field "no" Decode.int)
        (DecodeExt.withDefault Env.defaultName <| Decode.field "name" Decode.string)
        (DecodeExt.withDefault "" <| Decode.field "trip" Decode.string)
        (Decode.field "text" (Decode.oneOf [ Decode.string, Decode.null "" ]))
        (Decode.field "ts" Decode.int)
        (Decode.field "media" (Decode.list Media.decoder))


view : EventHandlers msg a -> Config -> ThreadID -> Post -> Html msg
view eventHandlers cfg threadID post =
    let
        theme =
            cfg.theme
    in
    article [ stylePost theme ]
        [ viewPostHead eventHandlers cfg threadID post
        , viewBody eventHandlers threadID post
        ]


stylePost : Theme -> Attribute msg
stylePost theme =
    classes [ T.mb1, T.mb2_ns, T.br3, T.br4_ns, T.overflow_hidden, theme.bgPost ]


viewPostHead : EventHandlers msg a -> Config -> ThreadID -> Post -> Html msg
viewPostHead eventHandlers cfg threadID post =
    header [ stylePostHead cfg.theme ]
        (viewPostHeadElements eventHandlers cfg threadID post)


viewPostHeadElements : EventHandlers msg a -> Config -> ThreadID -> Post -> List (Html msg)
viewPostHeadElements eventHandlers { theme, timeZone } threadID post =
    [ viewPostNo eventHandlers theme threadID post
    , viewName theme post
    , viewPostTime timeZone post
    ]


stylePostHead : Theme -> Attribute msg
stylePostHead theme =
    classes
        [ T.f7
        , T.f6_ns
        , T.overflow_hidden
        , T.pb1
        , T.pl2
        , T.pl3_ns
        , theme.fgPostHead
        , theme.fontMono
        ]


viewPostNo : EventHandlers msg a -> Theme -> ThreadID -> Post -> Html msg
viewPostNo eventHandlers theme threadID post =
    viewHeadElement
        [ classes [ T.link, T.pointer, TE.sel_none, theme.fgPostNo ]
        , onClick (eventHandlers.onReplyToClicked threadID post.no)
        ]
        [ text ("#" ++ String.fromInt post.no) ]


viewName : Theme -> Post -> Html msg
viewName theme post =
    let
        htmlTrip =
            if String.isEmpty post.trip then
                nothing

            else
                span [ classes [ theme.fgPostTrip ] ]
                    [ text ("!" ++ post.trip) ]

        htmlName =
            span [ class theme.fgPostName, class T.dib ]
                [ text (String.left 32 post.name) ]
    in
    viewHeadElement [] [ htmlName, htmlTrip ]


viewPostTime : Maybe Zone -> Post -> Html msg
viewPostTime maybeZone post =
    viewHeadElement [] [ viewMaybeTime maybeZone post.ts ]


viewMaybeTime : Maybe Zone -> Int -> Html msg
viewMaybeTime maybeZone ts =
    maybeZone
        |> Maybe.map (viewTime ts)
        >> Maybe.withDefault (text "...")


viewTime : Int -> Zone -> Html msg
viewTime ts zone =
    let
        posixTime =
            Time.millisToPosix (1000 * ts)

        day =
            Time.toDay zone posixTime
                |> String.fromInt
                >> String.pad 2 '0'

        month =
            Time.toMonth zone posixTime
                |> toMonthName

        year =
            Time.toYear zone posixTime
                |> String.fromInt

        hours =
            Time.toHour zone posixTime
                |> String.fromInt
                >> String.pad 2 '0'

        minutes =
            Time.toMinute zone posixTime
                |> String.fromInt
                >> String.pad 2 '0'

        seconds =
            Time.toSecond zone posixTime
                |> String.fromInt
                >> String.pad 2 '0'
    in
    text <| String.concat [ year, "-", month, "-", day, " ", hours, ":", minutes, ":", seconds ]


toMonthName : Month -> String
toMonthName month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


viewBody : EventHandlers msg a -> ThreadID -> Post -> Html msg
viewBody eventHandlers threadID post =
    let
        style =
            classes [ T.overflow_hidden, T.pre ]
    in
    section
        [ style
        , Html.Attributes.style "white-space" "pre-wrap"
        ]
        [ viewListMedia eventHandlers threadID post.no post.media
        , viewPostText post.text
        ]


viewPostText : String -> Html msg
viewPostText str =
    if String.Extra.isBlank str then
        nothing

    else
        div [ classes [ T.ma2, T.ma3_ns ] ] [ text str ]


viewHeadElement : List (Attribute msg) -> List (Html msg) -> Html msg
viewHeadElement attrs =
    div (classes [ T.dib, T.mr2, T.pt2 ] :: attrs)


viewButtonHead : Theme -> String -> Html msg
viewButtonHead theme btnText =
    viewHeadElement
        []
        [ span [ class theme.fgTextButton ] [ text "[" ]
        , span [ classes [ T.underline, T.dim, theme.fgTextButton ] ] [ text btnText ]
        , span [ class theme.fgTextButton ] [ text "]" ]
        ]


viewListMedia : EventHandlers msg a -> ThreadID -> No -> List Media -> Html msg
viewListMedia eventHandlers threadID postNo listMedia =
    let
        style =
            classes [ T.fl, T.mr2, T.mb2, T.mr3_ns, T.mb3_ns, T.flex, T.flex_wrap ]
    in
    div [ style ] <|
        List.map (viewMedia eventHandlers threadID postNo) listMedia


viewMedia : EventHandlers msg a -> ThreadID -> No -> Media -> Html msg
viewMedia eventHandlers threadID postNo media =
    let
        styleMediaContainer =
            classes [ T.ml2, T.mt2, T.ml3_ns, T.mt3_ns ]

        attrs =
            [ href (Media.url media)
            , onClick (eventHandlers.onMediaClicked threadID postNo media.id)
            ]
    in
    if media.isPreview then
        div [ class T.db, styleMediaContainer ]
            [ a attrs [ viewMediaPreview media ]
            ]

    else
        div [ styleMediaContainer ]
            [ a attrs [ viewMediaFull media ]
            ]


viewMediaPreview : Media -> Html msg
viewMediaPreview media =
    let
        urlPreview =
            Url.Builder.crossOrigin Env.urlThumb [ media.id ] []

        attrsSizes =
            if media.width >= media.height then
                mediaSizes media.width media.height width height

            else
                mediaSizes media.height media.width height width
    in
    img
        (attrsSizes
            ++ [ stylePostMedia
               , src (Media.urlPreview media)
               , alt "[Attached media]"
               ]
        )
        []


mediaSizes : Int -> Int -> (Int -> Attribute msg) -> (Int -> Attribute msg) -> List (Attribute msg)
mediaSizes big small attrBig attrSmall =
    let
        pBig =
            Basics.min 200 big

        pSmall =
            round <| toFloat pBig * (toFloat small / toFloat big)
    in
    [ attrBig pBig, attrSmall pSmall ]


viewMediaFull : Media -> Html msg
viewMediaFull media =
    img
        [ stylePostMedia
        , width media.width
        , src (Media.url media)
        , alt "[Attached media]"
        ]
        []


stylePostMedia : Attribute msg
stylePostMedia =
    classes [ T.db, T.br1, T.pointer, T.mw_100 ]



-- OP-post functions


viewOp : EventHandlersOP msg -> Config -> Op -> Html msg
viewOp eventHandlers cfg op =
    let
        theme =
            cfg.theme
    in
    article [ stylePost theme ]
        [ viewOpHead eventHandlers cfg op
        , viewBody eventHandlers op.threadID op.post
        ]


opDomID : Int -> String
opDomID threadID =
    "thread-" ++ String.fromInt threadID


viewOpHead : EventHandlersOP msg -> Config -> Op -> Html msg
viewOpHead eventHandlers cfg { threadID, subject, post } =
    let
        theme =
            cfg.theme
    in
    header [ stylePostHead theme ]
        [ div [ classes [ T.pt2 ] ]
            [ viewPrevNextControls eventHandlers theme threadID
            , viewOpNo theme threadID
            , viewSubject theme threadID subject
            , viewReply eventHandlers theme threadID
            , viewShowAll theme threadID
            ]
        , div []
            (viewPostHeadElements eventHandlers cfg threadID post)
        ]


viewOpNo : Theme -> ThreadID -> Html msg
viewOpNo theme threadID =
    viewThreadLink threadID
        [ class TE.sel_none ]
        [ viewButtonHead theme (String.fromInt threadID) ]


viewPrevNextControls : EventHandlersOP msg -> Theme -> ThreadID -> Html msg
viewPrevNextControls eventHandlers theme threadID =
    span
        [ id (opDomID threadID)
        , classes [ T.mr2, TE.sel_none ]
        ]
        [ viewNextThread eventHandlers theme threadID
        , text "|"
        , viewPrevThread eventHandlers theme threadID
        ]


viewNextThread : EventHandlersOP msg -> Theme -> ThreadID -> Html msg
viewNextThread eventHandlers theme threadID =
    let
        attrs =
            eventHandlers.onNextThreadClicked
                |> Maybe.map (attrsPrevNext theme threadID)
                >> Maybe.withDefault []
    in
    span (title "Go To Next Thread" :: attrs) [ text "[▼" ]


viewPrevThread : EventHandlersOP msg -> Theme -> ThreadID -> Html msg
viewPrevThread eventHandlers theme threadID =
    let
        attrs =
            eventHandlers.onPrevThreadClicked
                |> Maybe.map (attrsPrevNext theme threadID)
                >> Maybe.withDefault [ class theme.fgButtonDisabled ]
    in
    span (title "Go To Previous Thread" :: attrs) [ text "▲]" ]


attrsPrevNext : Theme -> Int -> (Int -> msg) -> List (Attribute msg)
attrsPrevNext theme threadID toMsg =
    [ onClick (toMsg threadID)
    , classes
        [ T.link
        , T.pointer
        , theme.fgTextButton
        , T.dim
        ]
    ]


viewReply : EventHandlersOP msg -> Theme -> ThreadID -> Html msg
viewReply eventHandlers theme threadID =
    span
        [ classes [ T.link, T.pointer, TE.sel_none ]
        , onClick (eventHandlers.onReplyToClicked threadID 0)
        ]
        [ viewButtonHead theme "Reply" ]


viewShowAll : Theme -> ThreadID -> Html msg
viewShowAll theme threadID =
    viewThreadLink threadID
        [ class TE.sel_none ]
        [ viewButtonHead theme "Show All" ]


viewSubject : Theme -> ThreadID -> Maybe String -> Html msg
viewSubject theme threadID subject =
    let
        style =
            classes [ T.f5, T.f4_ns, T.link, T.pointer, theme.fgThreadSubject ]

        strSubject =
            Maybe.withDefault ("Thread #" ++ String.fromInt threadID) subject
    in
    viewThreadLink threadID
        []
        [ viewHeadElement
            [ style ]
            [ text strSubject ]
        ]


viewThreadLink : ThreadID -> List (Attribute msg) -> List (Html msg) -> Html msg
viewThreadLink threadID attrs =
    a (href (Route.link (Route.Thread threadID)) :: attrs)
