module Api ( addPage
           , removePage
           , requestTree
           , requestTopic
           ) where

import Data.Maybe
import Data.Page
import Data.Traversable
import Data.Tuple
import Network.HTTP.Affjax.Response
import Prelude

import Control.Monad.Aff (Aff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log)
import Data.Argonaut.Core as Argo
import Data.Argonaut.Parser (jsonParser)
import Data.Either (Either(..))
import Data.Either as Either
import Data.HTTP.Method (Method(..))
import Data.Int (floor)
import Data.Newtype (unwrap, wrap)
import Data.StrMap as StrMap
import Network.HTTP.Affjax (AJAX, affjax, post, defaultRequest, post_)


endpoint :: String
endpoint = "/jsonrpc"

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
    js :: Argo.Json
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


requestTree
  :: forall aff. String
  -> Aff (ajax :: AJAX, console :: CONSOLE | aff) (Either String Tree)
requestTree user = do
  ({ status, response }) <- post endpoint $ Argo.stringify js

  pure do
    parsed <- jsonParser response

    result <- Either.note "invalid result" $ Argo.foldJsonObject Nothing (\strMap -> StrMap.lookup "result" strMap) parsed

    parseTree result

  where
    js :: Argo.Json
    js = Argo.fromObject $ StrMap.fromFoldable
         [ Tuple "jsonrpc" $ Argo.fromString "2.0"
         , Tuple "params" $ Argo.fromArray [ Argo.fromString user ]
         , Tuple "method" $ Argo.fromString "get_topics"
         , Tuple "id" $ Argo.fromNumber 1.0
         ]

    parseTree :: Argo.Json -> Either String Tree
    parseTree js = do
      type_ <- Either.note "invalid or missing type" $ Argo.foldJsonObject
               Nothing 
               (\strMap -> StrMap.lookup "type" strMap >>= Argo.toString)
               js

      case type_ of
        "topic" -> parseTopic js
        "node" -> parseNode js
        _ -> Left $ "invalid type " <> type_

    parseTopic :: Argo.Json -> Either String Tree
    parseTopic js = do
      id <- Either.note "invalid id" $ Argo.foldJsonObject
            Nothing
            (\strMap -> StrMap.lookup "id" strMap >>= Argo.toString)
            js

      title <- Either.note "invalid title" $ Argo.foldJsonObject
               Nothing
               (\strMap -> StrMap.lookup "title" strMap >>= Argo.toString)
               js
  
      active <- Either.note "invalid 'active'" $ Argo.foldJsonObject
                Nothing
                (\strMap -> StrMap.lookup "active" strMap >>= Argo.toBoolean)
                js

      uuid <- Either.note "Invalid uuid" $ Argo.foldJsonObject
              Nothing
              (\strMap -> StrMap.lookup "uuid" strMap >>= Argo.toString)
              js

      done <- Either.note "Invalid 'done'" $ Argo.foldJsonObject
              Nothing
              (\strMap -> StrMap.lookup "done" strMap >>= Argo.toNumber >>= (pure <<< floor))              
              js
              
      size <- Either.note "Invalid 'size'" $ Argo.foldJsonObject
              Nothing
              (\strMap -> StrMap.lookup "size" strMap >>= Argo.toNumber >>= (pure <<< floor))
              js

      pure $ Topic { id: wrap id, title, active, uuid, size, done }
      

    parseNode :: Argo.Json -> Either String Tree
    parseNode js = do
      id <- Either.note "invalid id" $ Argo.foldJsonObject
            Nothing
            (\strMap -> StrMap.lookup "id" strMap >>= Argo.toString)
            js
      
      title <- Either.note "invalid title" $ Argo.foldJsonObject
               Nothing
               (\strMap -> StrMap.lookup "title" strMap >>= Argo.toString)
               js

      childrenArr <- Either.note "invalid children" $ Argo.foldJsonObject
                     Nothing
                     (\strMap -> StrMap.lookup "children" strMap >>= Argo.toArray)
                     js

      children <- sequence $ map parseTree childrenArr

      pure $ Node { id: wrap id, title, children }


json :: String -> String -> Argo.Json
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


requestTopic
  :: forall eff. PageId
  -> String
  -> Aff ( console ::CONSOLE
         , ajax :: AJAX | eff ) (Either String (Array Infobit))
requestTopic pageId user = do
  ({ status, response }) <- post endpoint $ Argo.stringify callObj

  pure $ parseResp response

  where

    parseResp :: String -> Either String (Array Infobit)
    parseResp r = do
      parsed <- jsonParser r

      result <- Either.note "invalid result" $ Argo.foldJsonObject
                Nothing
                (\d -> StrMap.lookup "result" d >>= Argo.toArray)
                parsed
      
      sequence $ map parseInfobit result 

    callObj :: Argo.Json
    callObj = Argo.fromObject $ StrMap.fromFoldable
         [ Tuple "jsonrpc" (Argo.fromString "2.0")
         , Tuple "params"
           $ Argo.fromArray
           [ Argo.fromString user
           , Argo.fromString (unwrap pageId)
           ]
         , Tuple "method" (Argo.fromString "topic_get_infobits")
         , Tuple "id" (Argo.fromNumber 1.0)
         ]
    
    parseInfobit :: Argo.Json -> Either String Infobit
    parseInfobit json = do
      id <- Either.note "invalid 'id'" $ Argo.foldJsonObject
            Nothing
            (\strMap -> StrMap.lookup "id" strMap >>= Argo.toString)
            json

      title <- Either.note "invalid 'title'" $ Argo.foldJsonObject
               Nothing
               (\strMap -> StrMap.lookup "title" strMap >>= Argo.toString)
               json

      done <- Either.note "invalid 'done'" $ Argo.foldJsonObject
              Nothing
              (\strMap -> StrMap.lookup "done" strMap >>= Argo.toBoolean)
              json

      pure $ Infobit { title, id: wrap id, done }
