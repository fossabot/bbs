module Env exposing
    ( bbsName
    , defaultName
    , fileFormats
    , maxPerPage
    , minPerPage
    , threadsPerPage
    , urlAPI
    , urlImage
    , urlServer
    , urlThumb
    )

import Url.Builder


urlServer : String
urlServer =
    "https://bbs.hedlx.org"


urlAPI : String
urlAPI =
    Url.Builder.crossOrigin urlServer [ "api" ] []


urlImage : String
urlImage =
    Url.Builder.crossOrigin urlServer [ "i" ] []


urlThumb : String
urlThumb =
    Url.Builder.crossOrigin urlServer [ "t" ] []


fileFormats : List String
fileFormats =
    [ "image/png", "image/jpeg" ]


defaultName : String
defaultName =
    "Anonymous"


bbsName : String
bbsName =
    "hedλx BBS"


minPerPage : Int
minPerPage =
    1


maxPerPage : Int
maxPerPage =
    100


threadsPerPage : Int
threadsPerPage =
    8
