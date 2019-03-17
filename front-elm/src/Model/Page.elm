module Model.Page exposing
    ( Page(..)
    , State(..)
    , isLoading
    , mapContent
    , mapIndex
    , mapLoading
    , mapPostForm
    , mapThread
    , postForm
    , title
    , withLoadingDefault
    )

import Model.PostForm exposing (PostForm)
import Model.Thread
import Model.ThreadPreview


type Page
    = NotFound
    | Index (State () (List Model.ThreadPreview.ThreadPreview))
    | Thread (State Int Model.Thread.Thread) PostForm
    | NewThread PostForm


type State a b
    = Loading a
    | Content b


title page =
    case page of
        NotFound ->
            "NotFound"

        Index _ ->
            ""

        Thread (Loading _) _ ->
            "..."

        Thread (Content thread) _ ->
            thread.subject
                |> Maybe.withDefault ("Thread #" ++ String.fromInt thread.id)

        NewThread _ ->
            "New Thread"


mapContent f state =
    case state of
        Content data ->
            Content (f data)

        Loading loadData ->
            Loading loadData


mapLoading f state =
    case state of
        Loading data ->
            Loading (f data)

        Content data ->
            Content data


withLoadingDefault placeholder state =
    case state of
        Loading _ ->
            placeholder

        Content data ->
            data


mapIndex f page =
    case page of
        Index threadPreviews ->
            Index (f threadPreviews)

        _ ->
            page


mapPostForm f page =
    case page of
        NewThread form ->
            NewThread (f form)

        Thread state form ->
            Thread state (f form)

        _ ->
            page


postForm page =
    case page of
        NewThread form ->
            Just form

        Thread _ form ->
            Just form

        _ ->
            Nothing


mapThread f page =
    case page of
        Thread state form ->
            Thread (f state) form

        _ ->
            page


isLoading page =
    case page of
        Index (Loading _) ->
            True

        Thread (Loading _) _ ->
            True

        _ ->
            False
