module PageList ( spec
                , initialState
                , State (..)
                , Action (..)
                ) where

import Api
import Data.Array as Array
import Data.Lens
import Data.Maybe
import Data.Page
import Data.Traversable
import Data.Tuple
import Prelude
import Data.Int (floor)
import Control.Monad.Aff (Aff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (log)
import Control.Monad.Trans.Class (lift)
import Data.Either (Either(..))
import Data.Either as Either
import Data.Int (toNumber)
import Data.List as L
import Data.Newtype (wrap)
import React as R
import React.DOM as R
import React.DOM.Props as RP
import Thermite as T
import Data.String (joinWith, replaceAll) as String
import Data.Newtype (wrap, unwrap)

data State = State { user :: String
                   , field :: String
                   , tree :: Tree
                   , infobits :: Maybe (Array Infobit)
                   }

data Action = AddPage String
            | RemovePage String 
            | Reload
            | ViewTopic PageId
            | CloseModal

panel :: PageId -> String
panel pageId = "/panel/pages/" <> (unwrap pageId) <> "/edit"


icon :: String -> R.ReactElement
icon name =
  R.i
  [ RP.className $ "icon fa fa-" <> name ]
  []

badge :: String -> R.ReactElement
badge content =
  R.i
  [ RP.className "badge" ]
  [ R.text content ]


classList :: Array (Tuple String Boolean) -> String
classList xs =
  let
    active = Array.filter (\(Tuple a b) -> b) xs

    onlyClasses = map (\(Tuple a _) -> a) active

    concatenated = String.joinWith " " onlyClasses

  in concatenated


renderTree depth dispatch (Topic { title, id, active, uuid, done, size }) =
  R.div
  [ RP.className $ classList
    [ Tuple "page-tree__topic" true
    , Tuple "page-tree__topic--active" active
    ]
  ]      
  [ R.input
    [ RP._type "checkbox"
    , RP.onChange \_ -> dispatch (if active then RemovePage uuid else AddPage uuid)
    , RP.checked active
    ]
    []
  , R.span
    [ RP.className "page-tree__topic-title"
    , if 0 < size
      then RP.onClick \_ -> dispatch (ViewTopic id)
      else RP.title "This topic has no infobits."
    ]
    [ R.text title ]

  , if 0 == size
    then icon "exclamation-triangle"
    else R.text ""

  , if active && (0 < size) 
    then badge $ (show $ floor $ 100.0 * (toNumber done) / (toNumber size)) <> "%"
    else R.text ""

  , R.a
    [ RP.href $ panel id
    , RP.className "page-tree__edit-page-link"
    , RP.target "_blank"
    ]
    [ icon "edit"
    ]
  ]



renderTree depth dispatch (Node { title, id, children }) =
  let
    htmlId = String.replaceAll (wrap "/") (wrap "-") (unwrap id)
  in 
  R.div
  [ RP.className $ classList
    [ Tuple "page-tree__node" true
    , Tuple "page-tree__node--always-expanded" (depth < 2)
    ]
  ]
  [ R.label
    [ RP.className "page-tree__node-header"
    , RP.htmlFor htmlId
    ]
    [ icon "folder"
    , R.span
      [ RP.className "page-tree__node-title" ]
      [ R.text title ]
    ]

  , R.input
    [ RP._type "checkbox"
    , RP._id htmlId
    , RP.className "page-tree__collapser-checkbox"
    ]
    []

  , R.div
    [ RP.className "page-tree__children" ]
    (map (renderTree (depth + 1) dispatch) children)
  ]



renderInfobit :: Infobit -> R.ReactElement
renderInfobit (Infobit { title, done, id }) =
  R.div
  [ RP.className $ classList
    [ Tuple "infobits-list__item" true
    , Tuple "infobits-list__item--done" done
    ]
  ]
  [ if done
    then icon "check"
    else icon "times"

  , R.span
    [ RP.className "infobits-list__item__title" ]
    [ R.text title ]

  , R.a
    [ RP.target "_blank"
    , RP.href $ panel id
    ]
    [ icon "edit" ]

  ]

renderInfobits :: Array Infobit -> R.ReactElement
renderInfobits infobits =
  R.div
  [ RP.className "infobits-list" ]
  (map renderInfobit infobits)


newRender :: T.Render State _ Action
newRender dispatch _ (State { tree, infobits }) _ =
  [ R.div
    [ RP.className "page-tree" ]
    [ renderTree 0 dispatch tree ]
  , case infobits of
      Nothing -> R.text ""
      Just theBits -> renderModal "Infobits" dispatch CloseModal $ renderInfobits theBits
  ]

--renderModal :: R.ReactElement -> Action -> R.ReactElement
renderModal title dispatch action content =
  R.div
  [ RP.className "my-modal" ]
  [ R.div
    [ RP.className "my-modal__layer"
    , RP.onClick \_ -> dispatch action
    ]
    []

  , R.div
    [ RP.className "my-modal__box" ]
    [ R.div
      [ RP.className "my-modal__box__header" ]
      [ R.text title ]
    , R.div
      [ RP.className "my-modal__box__body" ]
      [ content ]
    ]
  ]



performAction :: T.PerformAction _ State _ Action
performAction Reload (State { user, field }) _ = do
  eitherTree <- lift $ requestTree user

  void $ case eitherTree of
    Right newTree -> do
      void $ T.modifyState \(State { user, field, tree, infobits }) ->
        State { user, field, tree: newTree, infobits }
    Left err -> do
      liftEff $ log $ "Unable to update pages: " <> err


performAction (RemovePage uuid) (State { user, field }) _ = void do
  void $ lift $ removePage user field uuid  
  eitherTree <- lift $ requestTree user

  void $ case eitherTree of
    Right newTree -> do
      void $ T.modifyState \(State { user, field, tree, infobits }) ->
        State { user, field, tree: newTree, infobits }
    Left err -> do
      liftEff $ log $ "Unable to remove update pages: " <> err

  
performAction (AddPage uuid) (State { user, field }) _ = void do
  void $ lift $ addPage user field uuid
  eitherTree <- lift $ requestTree user

  void $ case eitherTree of
    Right newTree -> do
      void $ T.modifyState \(State { user, field, tree, infobits }) ->
        State { user, field, tree: newTree, infobits }
    Left err -> do
      liftEff $ log $ "Unable to get topics: " <> err
  

performAction (ViewTopic pageId) (State { user, field }) _ = void do
  eitherInfobits <- lift $ requestTopic pageId user

  void $ case eitherInfobits of
    Right theBits -> do
      void $ T.modifyState \(State { user, field, infobits, tree }) ->
        State { user, field, tree, infobits: Just theBits }

    Left error -> do
      liftEff $ log $ "Error while retrieving infobits: " <> error


performAction CloseModal _ _ = void do
  T.modifyState \(State { user, field, infobits, tree }) ->
    State { user, field, tree, infobits: Nothing }


spec :: T.Spec _ State _ Action
spec = T.simpleSpec performAction newRender


initialState :: String -> String -> Tree -> State
initialState user field tree =
  State { user, field, tree, infobits: Nothing }
