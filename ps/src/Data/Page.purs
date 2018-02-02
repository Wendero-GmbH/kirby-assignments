module Data.Page where

import Prelude

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
