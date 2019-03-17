module Commands exposing
    ( blur
    , createPost
    , createThread
    , focus
    , getThreads
    , init
    , redirect
    , scrollPageToTop
    , uploadFile
    )

import Browser.Dom as Dom
import Browser.Navigation as Nav
import Env
import File exposing (File)
import Http
import Json.Decode as Decode
import Model exposing (Model)
import Model.Limits
import Model.Page as Page
import Model.Thread
import Model.Threads
import Msg exposing (Msg)
import Route
import Task
import Time
import Url.Builder


init : Model -> Cmd Msg
init model =
    let
        pageSpecific =
            case model.page of
                Page.Index (Page.Loading _) ->
                    getThreads

                Page.Thread (Page.Loading tID) _ ->
                    getThread tID

                _ ->
                    Cmd.none

        limitsInit =
            if Model.Limits.hasUndefined model.cfg.limits then
                getLimits

            else
                Cmd.none
    in
    Cmd.batch [ limitsInit, getTimeZone, pageSpecific ]


redirect : List String -> Model -> Cmd Msg
redirect pagePath model =
    Nav.pushUrl model.cfg.key <| Route.internalLink pagePath


scrollPageToTop : Cmd Msg
scrollPageToTop =
    Dom.setViewportOf "page-content" 0.0 0.0
        |> Task.attempt (\_ -> Msg.Empty)


focus : String -> Cmd Msg
focus id =
    Dom.focus id
        |> Task.attempt (\_ -> Msg.Empty)


blur : String -> Cmd Msg
blur id =
    Dom.blur id
        |> Task.attempt (\_ -> Msg.Empty)


getTimeZone : Cmd Msg
getTimeZone =
    Time.here |> Task.perform Msg.GotTimeZone


getLimits : Cmd Msg
getLimits =
    Http.get
        { url = Url.Builder.crossOrigin Env.serverUrl [ "limits" ] []
        , expect = Http.expectJson Msg.GotLimits Model.Limits.decoder
        }


getThreads : Cmd Msg
getThreads =
    Http.get
        { url = Url.Builder.crossOrigin Env.serverUrl [ "threads" ] []
        , expect = Http.expectJson Msg.GotThreads Model.Threads.decoder
        }


getThread : Int -> Cmd Msg
getThread threadID =
    Http.get
        { url = Url.Builder.crossOrigin Env.serverUrl [ "threads", String.fromInt threadID ] []
        , expect = Http.expectJson Msg.GotThread (Model.Thread.decoder threadID)
        }


uploadFile : (Result Http.Error String -> Msg) -> File -> Cmd Msg
uploadFile fromMediaIdToMsg file =
    let
        path =
            [ "upload" ]
    in
    Http.post
        { url = Url.Builder.crossOrigin Env.serverUrl path []
        , body = Http.multipartBody [ Http.filePart "media" file ]
        , expect = Http.expectJson fromMediaIdToMsg (Decode.field "id" Decode.string)
        }


createThread : Http.Body -> Cmd Msg
createThread formPostBody =
    let
        path =
            [ "threads" ]
    in
    Http.post
        { url = Url.Builder.crossOrigin Env.serverUrl path []
        , body = formPostBody
        , expect = Http.expectWhatever Msg.ThreadCreated
        }


createPost : Int -> Http.Body -> Cmd Msg
createPost threadID formPostBody =
    let
        path =
            [ "threads", String.fromInt threadID ]
    in
    Http.post
        { url = Url.Builder.crossOrigin Env.serverUrl path []
        , body = formPostBody
        , expect = Http.expectWhatever (Msg.PostCreated threadID)
        }
