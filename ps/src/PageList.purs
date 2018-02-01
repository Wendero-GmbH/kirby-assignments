module PageList where

import Prelude
import Control.Monad.Aff (Aff)
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
import Data.List as L
import Network.HTTP.Affjax.Response

import Data.Int (ceil, toNumber)
import Control.Monad.Eff.Console (log)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Aff (launchAff)
import Data.HTTP.Method (Method(..))
import Network.HTTP.Affjax (AJAX, affjax, post, defaultRequest, post_)
import Data.Argonaut.Core as Argo
import Data.StrMap as StrMap
import Data.Argonaut.Parser (jsonParser)
import Data.Traversable

data Page = Page { uuid :: String
                 , active :: Boolean
                 , title :: String
                 , infobits :: Int
                 , completed :: Int
                 }


instance showPage :: Show Page where
  show (Page { uuid, title, active, infobits, completed}) =
    "Page " <> uuid
    <> " " <> title
    <> " " <> show active
    <> " read " <> (show completed) <> " of " <> (show infobits)

type State = Array Page

data Action = AddPage String
            | RemovePage String 
            | Reload


render :: T.Render State _ Action
render dispatch _ state _ =
  [ R.ul
    [ RP.className "input-list field-grid cf" ]
    (map renderPage state)
  , R.div
    [ RP.onClick \_ -> dispatch $ Reload ]
    [ R.text "Reload" ]
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
                     , opacity: "0.3"
                     , transformOrigin: "left"
                     , transform: "scaleX(" <> (show $ (toNumber completed) / (toNumber infobits)) <> ")"
                     }
          ]
          []
        ]
      ]

collapseMaybe
  :: forall a b c
   . a
  -> Either a (Maybe b)
  -> Either a b
collapseMaybe _ (Right (Just x)) = Right x
collapseMaybe a _ = Left a

addPage
  :: String
  -> String
  -> String
  -> forall aff. Aff (ajax :: AJAX | aff) Boolean
addPage user field page = do
  _ <- post_ endpoint (Argo.stringify js)
  pure true
  
  where
    js = Argo.fromObject $ StrMap.fromFoldable
         [ Tuple "jsonrpc" (Argo.fromString "2.0")
         , Tuple "params"
           $ Argo.fromArray
           [ Argo.fromString user
           , Argo.fromString field
           , Argo.fromString page
           ]
         , Tuple "method" (Argo.fromString "user_field_add_page")
         , Tuple "id" (Argo.fromNumber 12.0)
         ]



removePage
  :: String
  -> String
  -> String
  -> forall aff. Aff (ajax :: AJAX | aff) Boolean
removePage user field page = do
  _ <- post_ endpoint (Argo.stringify js)
  pure true
  
  where
    js = Argo.fromObject $ StrMap.fromFoldable
         [ Tuple "jsonrpc" (Argo.fromString "2.0")
         , Tuple "params"
           $ Argo.fromArray
           [ Argo.fromString user
           , Argo.fromString field
           , Argo.fromString page
           ]
         , Tuple "method" (Argo.fromString "user_field_remove_page")
         , Tuple "id" (Argo.fromNumber 12.0)
         ]



requestPages
  :: String
  -> String
  -> forall aff. Aff (ajax :: AJAX | aff) (Either String (Array Page))
requestPages user field = do
  {status, response} <- post endpoint (Argo.stringify (json user field))
  pure $ collapseMaybe "unable to parse json" $ do
    dec <- jsonParser response
    pure $ do
      members <- Argo.foldJsonObject
                 Nothing
                 (StrMap.lookup "result")
                 dec
      arr <- Argo.foldJsonArray
             Nothing
             Just
             members
      sequence $ map (\el -> do
        title_ <- Argo.foldJsonObject
                  Nothing
                  (StrMap.lookup "title")
                  el
        title <- Argo.foldJsonString
                 Nothing
                 Just
                 title_
        active_ <- Argo.foldJsonObject
                   Nothing
                   (StrMap.lookup "active")
                   el
        active <- Argo.foldJsonBoolean
                  Nothing
                  Just
                  active_
        uuid_ <- Argo.foldJsonObject
                 Nothing
                 (StrMap.lookup "uuid")
                 el
        uuid <- Argo.foldJsonString
                Nothing
                Just
                uuid_
        infobits_ <- Argo.foldJsonObject
                     Nothing
                     (StrMap.lookup "infobits")
                     el
        infobits <- Argo.foldJsonNumber
                    Nothing
                    (Just <<< ceil)
                    infobits_
        completed_ <- Argo.foldJsonObject
                      Nothing
                      (StrMap.lookup "completed")
                      el
        completed <- Argo.foldJsonNumber
                     Nothing
                     (Just <<< ceil)
                     completed_
        Just $ Page { title, uuid, active, infobits, completed }) arr



json user field = Argo.fromObject $ StrMap.fromFoldable
            [ Tuple "jsonrpc" (Argo.fromString "2.0")
            , Tuple "params"
              $ Argo.fromArray
              [ Argo.fromString user
              , Argo.fromString field
              ]
            , Tuple "method" (Argo.fromString "user_field_get_pages")
            , Tuple "id" (Argo.fromNumber 12.0)
            ]

endpoint :: String
endpoint = "http://localhost:8080/jsonrpc"



performAction :: T.PerformAction _ State _ Action
performAction Reload _ _ = do
  pages <- lift $ requestPages "photz" "assignments"

  _ <- case pages of
    Right x -> T.modifyState \_ -> x
    _ -> T.modifyState \state -> state

  _ <- liftEff $ log $ show $ pages

  pure unit


performAction (RemovePage uuid) _ _ = void do
  _ <- lift $ removePage "photz" "assignments" uuid  
  pages <- lift $ requestPages "photz" "assignments"

  _ <- case pages of
    Right x -> T.modifyState \_ -> x
    _ -> T.modifyState \state -> state

  _ <- liftEff $ log $ show $ pages

  pure unit
  
performAction (AddPage uuid) _ _ = void do
  _ <- lift $ addPage "photz" "assignments" uuid
  pages <- lift $ requestPages "photz" "assignments"

  _ <- case pages of
    Right x -> T.modifyState \_ -> x
    _ -> T.modifyState \state -> state

  _ <- liftEff $ log $ show $ pages

  pure unit
  
spec :: T.Spec _ State _ Action
spec = T.simpleSpec performAction render

initialState :: State
initialState = []
