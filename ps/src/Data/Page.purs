module Data.Page where

import Prelude
import Data.Newtype
import Data.Array as Array

newtype PageId = PageId String

derive instance newtypePageId :: Newtype PageId _

data Tree = Node { id :: PageId
                 , title :: String
                 , children :: Array Tree
                 }
          | Topic { id :: PageId
                  , title :: String
                  , active :: Boolean
                  , uuid :: String
                  , done :: Int
                  , size :: Int
                  }


data Infobit = Infobit { title :: String
                       , id :: PageId
                       , done :: Boolean
                       }

instance showTree :: Show Tree where
  show (Node { id, title, children }) =
    "Node ( " <> (unwrap id) <> " " <> title
    <> " "
    <> (Array.foldl (\nxt acc -> show acc <> " " <> show nxt) "" children)
    <> " )"
  show (Topic { id, title }) =
    "Topic ( " <> (unwrap id) <> " " <> title <> " )"

