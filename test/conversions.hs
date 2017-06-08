{-# LANGUAGE RankNTypes #-}
{- |
   Module      : Main
   Description : Basic conversion tests
   Copyright   : Ivan Lazar Miljenovic
   License     : MIT
   Maintainer  : Ivan.Miljenovic@gmail.com



 -}
module Main (main) where

import Streaming.Conduit

import qualified Data.Conduit      as C
import qualified Data.Conduit.List as C
import qualified Streaming         as S
import qualified Streaming.Prelude as S

import Test.Hspec
import Test.Hspec.QuickCheck

import Data.Functor.Identity (Identity, runIdentity)

--------------------------------------------------------------------------------

main :: IO ()
main = hspec $ do
  describe "Stream -> Conduit" $ do
    prop "fromStream" $
      testPipeline (\xs f -> conduitList (fromStream (S.each xs) C..| C.map f))
    prop "fromStreamProducer" $
      testPipeline (\xs f -> conduitList (fromStreamProducer (S.each xs) C..| C.map f))
    prop "asConduit" $
      testPipeline (\xs f -> conduitList (C.sourceList xs C..| asConduit (S.map f)))

  describe "Conduit -> Stream" $ do
    prop "toStream" $
      testPipeline (\xs f -> streamList . S.map f $ toStream (C.sourceList xs))
    prop "asStream" $
      testPipeline (\xs f -> streamList . asStream (C.map f) $ S.each xs)

conduitList :: C.Source Identity a -> [a]
conduitList = runIdentity . C.sourceToList

streamList :: S.Stream (S.Of a) Identity () -> [a]
streamList = runIdentity . S.toList_

testPipeline :: (forall a. [a] -> (a -> a) -> [a]) -> [Int] -> Bool
testPipeline pipeline xs = pipeline xs plusOne == map plusOne xs

plusOne :: Int -> Int
plusOne = (+1)
