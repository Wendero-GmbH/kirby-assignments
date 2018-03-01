module Widget (main) where

import Control.Monad.Aff (Aff, launchAff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log)
import DOM (DOM)
import DOM.HTML (window) as DOM
import DOM.HTML.Document (body) as DOM
import DOM.HTML.Types (htmlDocumentToParentNode)
import DOM.HTML.Window (document) as DOM
import DOM.Node.ParentNode (querySelector, QuerySelector(..))
import Data.Argonaut.Core as Argo
import Data.Argonaut.Parser (jsonParser)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Either as Either
import Data.Int (floor, toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.StrMap as StrMap
import Data.Traversable (sequence)
import Data.Tuple (Tuple(..))
import Network.HTTP.Affjax (AJAX, post)
import Prelude
import React as R
import React.DOM as R
import React.DOM.Props as RP
import ReactDOM as ReactDOM
import Thermite as T
import Data.Newtype (wrap, unwrap, class Newtype)
import Control.Monad.Trans.Class (lift)

newtype Username = Username String

derive instance newtypeUsername :: Newtype Username _

data User = User { name :: Username
                 , incomplete :: Int
                 , completed :: Int
                 }

data State = State { users :: Array User }

data Action = NotifyUser Username
            | NoOp

icon :: String -> R.ReactElement
icon name =
  R.i
  [ RP.className $ "icon fa fa-" <> name ]
  []

userPath :: String -> String
userPath name = "/panel/users/" <> name <> "/edit"


render :: T.Render State _ Action
render dispatch _ (State { users }) _ =
  [ R.div
    []
    [ if Array.null users
      then R.text "There are no users with incomplete assignments"
      else renderUsers dispatch users
    ]
  ]

--renderUsers :: Array User -> R.ReactElement
renderUsers dispatch users =
  R.div
  [ RP.className "users-list" ]
  (map (renderUser dispatch) users)

--renderUser :: User -> R.ReactElement
renderUser dispatch (User { name, completed, incomplete }) =
  R.div
  [ RP.className "users-list__item" ]
  [ icon "user"

  , R.a
    [ RP.className "users-list__name"
    , RP.href $ userPath $ unwrap name
    ]
    [ R.text $ unwrap name ]

  , ratioBar completed incomplete

  , R.button
    [ RP.className "users-list__remind"
    , RP.title "Send a reminder"
    , RP.onClick \_ -> dispatch (NotifyUser name)
    ]
    [ icon "bell" ]
  ]

ratioBar :: Int -> Int -> R.ReactElement
ratioBar n d =
  R. div
  [ RP.className "ratio-bar" ]
  [ R.div
    [ RP.className "ratio-bar__piece ratio-bar__piece--left"
    , RP.style { flexGrow: show n }
    , RP.title $ show n <> " completed assignments"
    ]
    []
  , R.div
    [ RP.className "ratio-bar__piece ratio-bar__piece--right"
    , RP.style { flexGrow: show d }
    , RP.title $ show d <> " incomplete assignments"
    ]
    []
  ]

spec :: T.Spec _ State _ Action
spec = T.simpleSpec performAction render

initialState :: Array User -> State
initialState users = State { users: users }

performAction :: T.PerformAction _ State _ Action

performAction (NotifyUser username) _ _ = do
  void $ lift $ notifyUser username

performAction _ _ _ = do
  liftEff $ log "performAction called"

getElement s
 = (querySelector (QuerySelector s) <<< htmlDocumentToParentNode <=< DOM.document) =<< DOM.window

notifyUser :: forall eff. Username -> Aff ( ajax :: AJAX, console :: CONSOLE | eff ) Boolean
notifyUser username = do
  ({ status, response }) <- post "/jsonrpc" $ Argo.stringify methodCall
  pure $ status == (StatusCode 200)

  where

    methodCall :: Argo.Json
    methodCall = Argo.fromObject $ StrMap.fromFoldable
                 [ Tuple "jsonrpc" $ Argo.fromString "2.0"
                 , Tuple "params" $ Argo.fromArray
                   [ Argo.fromString (unwrap username) ]
                 , Tuple "method" $ Argo.fromString "notify_user"
                 , Tuple "id" $ Argo.fromNumber 1.0
                 ]

requestUsers :: forall eff. Aff ( ajax :: AJAX | eff ) (Either String (Array User))
requestUsers = do
  ({ status, response }) <- post "/jsonrpc" $ Argo.stringify req
  
  pure $ parseResp response

  where
    req :: Argo.Json
    req = Argo.fromObject $ StrMap.fromFoldable
          [ Tuple "jsonrpc" $ Argo.fromString "2.0"
          , Tuple "params" $ Argo.fromArray []
          , Tuple "method" $ Argo.fromString "get_users"
          , Tuple "id" $ Argo.fromNumber 1.0
          ]
    
    parseResp :: String -> Either String (Array User)
    parseResp raw = do
      parsed <- jsonParser raw

      arr <- Either.note "invalid 'result'" $ Argo.foldJsonObject
             Nothing
             (StrMap.lookup "result" >=> Argo.toArray)
             parsed

      sequence $ map parseUser arr

    parseUser :: Argo.Json -> Either String User
    parseUser raw = do
      name <- Either.note "invalid 'name'" $ Argo.foldJsonObject
              Nothing
              (StrMap.lookup "name" >=> Argo.toString)
              raw

      completed <- Either.note "invalid 'completed'" $ Argo.foldJsonObject
                   Nothing
                   (StrMap.lookup "completed" >=> Argo.toNumber)
                   raw

      incomplete <- Either.note "invalid 'incomplete'" $ Argo.foldJsonObject
                    Nothing
                    (StrMap.lookup "incomplete" >=> Argo.toNumber)
                    raw

      pure $ User { name: wrap name
                  , completed: Int.floor completed
                  , incomplete: Int.floor incomplete
                  }
    

main = launchAff do
  eitherUsers <- requestUsers

  void $ liftEff do
    let sel = ".overview-widget"

    maybeEl <- getElement sel

    case eitherUsers of
      Left err -> log "Unable to retrieve users"
      Right users -> 
        let
          component = T.createClass spec (initialState users)
          factory = R.createFactory component initialState
        in case maybeEl of
          Nothing -> log $ "Unable to find element " <> sel
          Just container ->
            void $ ReactDOM.render factory container
