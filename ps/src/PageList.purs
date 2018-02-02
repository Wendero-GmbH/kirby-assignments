module PageList where

import Prelude
import Data.Newtype (wrap)
import Data.Lens
import Data.List as L
import Data.Maybe
import Data.Tuple
import Data.Either (Either(..))
import Data.Either as Either
import Control.Monad.Aff (Aff)
import Control.Monad.Trans.Class (lift)
import React as R
import React.DOM as R
import React.DOM.Props as RP
import Thermite as T

import Data.Page
import Api

import Data.Int (ceil, toNumber)
import Control.Monad.Eff.Console (log)
import Control.Monad.Eff.Class (liftEff)

import Data.Traversable




data State = State { user :: String
                   , pages :: Array Page
                   , field :: String
                   }

data Action = AddPage String
            | RemovePage String 
            | Reload


render :: T.Render State _ Action
render dispatch _ (State { pages }) _ =
  [ R.ul
    [ RP.className "input-list field-grid cf" ]
    (map renderPage pages)
  ]

  where
    renderPage (Page { title, uuid, active, infobits, completed }) =
      R.li
      [ RP.className "input-list-item field-grid-item field-grid-item-1-2" ]
      [ R.label
        [ RP.className "input input-with-checkbox" ]
        [ R.input
          [ RP.className "checkbox"
          , RP._type "checkbox"
          , RP.onChange \_ -> dispatch (if active then RemovePage uuid else AddPage uuid)
          , RP.checked active
          , RP.style { position: "relative"
                     , zIndex: "10"
                     }
          ]
          []
        , R.span' [ R.text title ]
        , R.div
          [ RP.style { backgroundColor: "#74a237"
                     , position: "absolute"
                     , top: "0"
                     , left: "0"
                     , right: "0"
                     , bottom: "0"
                     , opacity: "0.2"
                     , transformOrigin: "left"
                     , transform: "scaleX(" <> (show $ (toNumber completed) / (toNumber infobits)) <> ")"
                     }
          ]
          []
        ]
      ]





performAction :: T.PerformAction _ State _ Action
performAction Reload (State { user, field }) _ = do
  pages <- lift $ requestPages user field

  _ <- case pages of
    Right newPages -> T.modifyState \(State { pages, user, field }) ->
      (State { pages: newPages, user, field })
    _ -> T.modifyState \state -> state

  pure unit


performAction (RemovePage uuid) (State { user, field }) _ = void do
  _ <- lift $ removePage user field uuid  
  pages <- lift $ requestPages user field

  _ <- case pages of
    Right newPages -> T.modifyState \(State { pages, user, field }) ->
      State { pages: newPages, user, field }
    _ -> T.modifyState \state -> state

  pure unit
  
performAction (AddPage uuid) (State { user, field }) _ = void do
  _ <- lift $ addPage user field uuid
  pages <- lift $ requestPages user field

  _ <- case pages of
    Right newPages -> T.modifyState \(State { pages, user, field }) ->
      State { pages: newPages, user, field }
    _ -> T.modifyState \state -> state

  pure unit
  
spec :: T.Spec _ State _ Action
spec = T.simpleSpec performAction render

initialState :: String -> String -> Array Page -> State
initialState user field pages = State { user, field, pages }
