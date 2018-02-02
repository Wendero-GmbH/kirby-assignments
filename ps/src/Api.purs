module Api where

import Data.Tuple
import Data.Either (Either(..))
import Data.Either as Either
import Prelude
import Control.Monad.Aff (Aff)
import Data.HTTP.Method (Method(..))
import Network.HTTP.Affjax (AJAX, affjax, post, defaultRequest, post_)
import Data.Argonaut.Core as Argo
import Data.StrMap as StrMap
import Data.Argonaut.Parser (jsonParser)
import Network.HTTP.Affjax.Response
import Data.Maybe
import Data.Traversable
import Data.Page
import Data.Int (ceil)

endpoint :: String
endpoint = "/jsonrpc"

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
