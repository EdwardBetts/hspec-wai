{-# LANGUAGE OverloadedStrings, TemplateHaskell #-}
module Test.Hspec.Wai.JSON (
-- $setup
  json
, FromValue(..)
) where

import           Data.ByteString.Lazy (ByteString)
import           Data.Aeson (Value, decode, encode)
import           Data.Aeson.QQ
import           Language.Haskell.TH.Quote

import           Test.Hspec.Wai
import           Test.Hspec.Wai.Matcher

-- $setup
-- The examples in this module assume that you have the @QuasiQuotes@ language
-- extension enabled and that "Data.ByteString.Lazy.Char8" is imported
-- qualified as @L@:
--
-- >>> :set -XQuasiQuotes
-- >>> import Data.ByteString.Lazy.Char8 as L

-- | A `QuasiQuoter` for constructing JSON values.
--
-- The constructed value is polymorph and unifies to instances of `FromValue`.
--
-- When used as a `ResponseMatcher` it matches a response with
--
--  * a status code of @200@
--
--  * a @Content-Type@ header with value @application/json@
--
--  * the specified JSON as response body
--
-- When used as a @ByteString@ it creates a ByteString from the specified JSON
-- that can be used as a request body for e.g. @POST@ and @PUT@ requests.
--
-- Example:
--
-- >>> L.putStrLn [json|[23, {foo: 42}]|]
-- [23,{"foo":42}]
json :: QuasiQuoter
json = QuasiQuoter {
  quoteExp = \input -> [|fromValue $(quoteExp aesonQQ input)|]
, quotePat = const $ error "No quotePat defined for Test.Hspec.Wai.JSON.json"
, quoteType = const $ error "No quoteType defined for Test.Hspec.Wai.JSON.json"
, quoteDec = const $ error "No quoteDec defined for Test.Hspec.Wai.JSON.json"
}

class FromValue a where
  fromValue :: Value -> a

instance FromValue ResponseMatcher where
  fromValue = ResponseMatcher 200 ["Content-Type" <:> "application/json"] . equalsJSON

equalsJSON :: Value -> MatchBody
equalsJSON expected = MatchBody matcher
  where
    matcher headers actualBody = case decode actualBody of
      Just actual | actual == expected -> Nothing
      _ -> let MatchBody m = bodyEquals (encode expected) in m headers actualBody

instance FromValue ByteString where
  fromValue = encode
