module Main where

import           Test.DocTest

main :: IO ()
main = doctest ["-isrc", "src/Test/Hspec/Wai/JSON.hs"]
