module Route exposing (initModel, internalLink, route)

import Browser.Navigation as Nav
import Model exposing (Flags, Model)
import Model.Config as Config exposing (Config)
import Model.Page as Page exposing (..)
import Model.Plugins as Plugins
import Model.PostForm as PostForm
import String.Extra
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser exposing (..)


routes : Config -> Page -> Parser (Page -> Page) Page
routes cfg page =
    oneOf
        [ oneOf [ top, s "threads" ]
            |> map (Index <| Loading ())
        , oneOf [ s "new", s "threads" </> s "new" ]
            |> map (NewThread (PostForm.init cfg.limits |> PostForm.setSubj ""))
        , oneOf [ int, s "threads" </> int ]
            |> map (routeThread cfg page)
        ]


routeThread : Config -> Page -> Int -> Page
routeThread cfg page threadID =
    case page of
        Thread (Loading currentThreadID) postForm ->
            if currentThreadID == threadID then
                Thread (Loading threadID) postForm

            else
                Thread (Loading threadID) (PostForm.init cfg.limits)

        _ ->
            Thread (Loading threadID) (PostForm.init cfg.limits)


route : Url -> Model -> Model
route url model =
    replacePathWithFragment url
        |> parse (routes model.cfg model.page)
        >> Maybe.map (\newPage -> { model | page = newPage })
        >> Maybe.withDefault { model | page = Page.NotFound }


internalLink : List String -> String
internalLink ls =
    let
        fixedPath =
            List.concatMap (String.split "/") ls
                |> List.filter (not << String.Extra.isBlank)
    in
    Builder.relative ("#" :: fixedPath) []


replacePathWithFragment : Url -> Url
replacePathWithFragment url =
    { url
        | path = Maybe.withDefault "" url.fragment
        , fragment = Just ""
    }


initModel : Flags -> Url -> Nav.Key -> Model
initModel _ url key =
    route url
        { cfg = Config.init url key
        , page = Page.NotFound
        , plugins = Plugins.init
        }
