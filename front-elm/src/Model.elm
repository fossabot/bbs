module Model exposing (Flags, Model, init)

import Json.Encode as Encode
import Model.Config as Config exposing (Config)
import Model.Page as Page exposing (Page)
import Model.Theme as Theme exposing (Theme)
import Route
import Spinner
import Url exposing (Url)


type alias Flags =
    Encode.Value


type alias Model =
    { cfg : Config
    , page : Page
    , spinner : Spinner.Model
    }


init flags url key =
    { cfg = Config.init url key
    , page = Route.route url
    , spinner = Spinner.init
    }
