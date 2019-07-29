module Frost.Plugins where

import Frost
import Frost.Plugin
import Frost.TimestampPlugin
import Frost.DefaultsMandatoryPlugin
import Data.List (find)
import Control.Monad
import Polysemy
import Polysemy.Error
import PolysemyContrib
import Text.Pandoc
import Text.Pandoc.Extensions
import Data.Map.Strict
import Data.Traversable

transform :: Member (Error DynamicError) r => [Plugin r] -> Pandoc -> Sem r Pandoc
transform plugins (Pandoc meta blocks) = do
  let plugin = (head plugins) -- TODO LOL, use all plugins, not one
  newMeta <- addToMeta plugin meta
  newBlocks <- traverse (extractFrostBlocks plugins) blocks
  return $ Pandoc newMeta (join newBlocks)

  where
    extractFrostBlocks plugins = (\case
        CodeBlock ("",[name],[]) content -> do
          let maybePlugin = find (\p -> "frost:" ++ pluginName p == name) plugins
          case maybePlugin of
            Just plugin ->  substitute plugin content
            Nothing -> return [HorizontalRule]
        otherwise -> return [otherwise])

plugins :: Member SystemEffect r => [Plugin r]
plugins = [ timestampPlugin
          , defaultsMandatoryPlugin
          ]


