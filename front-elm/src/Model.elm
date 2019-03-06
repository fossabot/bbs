module Model exposing (Flags, Model, init)

import Browser.Navigation as Nav
import Json.Encode as Encode
import Model.Page as Page exposing (Page)
import Model.Theme as Theme exposing (Theme)
import Model.Thread as Thread exposing (Thread)
import Model.ThreadForm as ThreadForm exposing (ThreadForm)
import Route
import Spinner
import Url exposing (Url)


type alias Flags =
    Encode.Value


type alias Model =
    { appPath : String
    , page : Page
    , key : Nav.Key
    , isLoading : Bool
    , theme : Theme
    , threads : List Thread
    , spinner : Spinner.Model
    }


init flags url key =
    let
        page =
            Route.route url
    in
    { appPath = url.path
    , page = page
    , key = key
    , isLoading = Page.isLoadingRequired page
    , theme = Theme.empty
    , threads = []
    , spinner = Spinner.init
    }
