module Main (main, widget) where

import Prelude

import Control.Monad.Aff (launchAff, Aff, Fiber)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log, logShow)
import Control.Monad.Maybe.Trans
import Control.Monad.Trans.Class (lift)
import DOM (DOM) as DOM
import DOM.Classy.Element (getAttribute)
import DOM.HTML (window) as DOM
import DOM.HTML.Document (body) as DOM
import DOM.HTML.Types (htmlDocumentToParentNode)
import DOM.HTML.Types (htmlElementToElement) as DOM
import DOM.HTML.Window (document) as DOM
import DOM.Node.Document (getElementsByClassName)
import DOM.Node.ParentNode (querySelector, QuerySelector(..))
import DOM.Node.Types (Element)
import Data.Either
import Data.Foldable (for_, traverse_)
import Data.Lens
import Data.List as L
import Data.Maybe
import Data.Tuple
import Network.HTTP.Affjax (AJAX, affjax)
import React as R
import React.DOM as R
import React.DOM.Props as RP
import ReactDOM as ReactDOM
import Thermite as T

import Api (requestTree)
import PageList as PageList
import Data.Page
import Widget as Widget

type State = Tuple (Maybe Int) PageList.State

data Action = PageListAction PageList.Action



spec :: T.Spec _ State _ Action
spec = T.focus _2 _PageListAction PageList.spec



_PageListAction :: Prism' Action PageList.Action
_PageListAction = prism' PageListAction unwrap
                  where
                    unwrap (PageListAction pageListAction) = Just pageListAction
                    unwrap _ = Nothing


getElement s
 = (querySelector (QuerySelector s) <<< htmlDocumentToParentNode <=< DOM.document) =<< DOM.window


main username fieldname = launchAff do

  eitherTree <- requestTree username

  void $ liftEff $ runMaybeT do
    container <- MaybeT $ getElement ".pages-list"

    tree <- MaybeT $ pure $ hush eitherTree

    let initialState = PageList.initialState
                       username
                       fieldname
                       tree

    let component = (T.createClass PageList.spec initialState)

    lift $ ReactDOM.render
      (R.createFactory component initialState)
      container

widget = Widget.main
