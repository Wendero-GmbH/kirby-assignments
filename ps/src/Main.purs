module Main where

import Prelude

import Control.Monad.Eff (Eff)
import Control.Monad.Aff (Aff, delay)
import Data.Lens
import Data.List as L
import Data.Maybe
import Data.Tuple
import Data.Either
import Control.Monad.Aff (Aff)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Eff.Console (CONSOLE, log, logShow)
import React as R
import React.DOM as R
import React.DOM.Props as RP
import Thermite as T
import ReactDOM as ReactDOM
import DOM.Node.Document (getElementsByClassName)
import DOM.HTML.Types (htmlDocumentToParentNode)

import DOM (DOM) as DOM
import DOM.HTML (window) as DOM
import DOM.HTML.Document (body) as DOM
import DOM.HTML.Types (htmlElementToElement) as DOM
import DOM.HTML.Window (document) as DOM
import Data.Foldable (for_, traverse_)
import DOM.Node.ParentNode (querySelector, QuerySelector(..))

import PageList as PageList

type State = Tuple (Maybe Int) PageList.State

data Action = PageListAction PageList.Action



spec :: T.Spec _ State _ Action
spec = T.focus _2 _PageListAction PageList.spec



_PageListAction :: Prism' Action PageList.Action
_PageListAction = prism' PageListAction unwrap
                  where
                    unwrap (PageListAction pageListAction) = Just pageListAction
                    unwrap _ = Nothing

initialState :: State
initialState = Tuple Nothing PageList.initialState


getElement s
  = (querySelector (QuerySelector s) <<< htmlDocumentToParentNode <=< DOM.document) =<< DOM.window


main = void do
  let component = T.createClass spec initialState

  container <- getElement ".pages-list"
  traverse_
    (ReactDOM.render (R.createFactory component unit))
    container


