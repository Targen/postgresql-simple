{-# LANGUAGE RecordWildCards #-}

------------------------------------------------------------------------------
-- |
-- Module:      Database.PostgreSQL.Simple.FromRow
-- Copyright:   (c) 2011 Leon P Smith
-- License:     BSD3
-- Maintainer:  Leon P Smith <leon@melding-monads.com>
-- Stability:   experimental
-- Portability: portable
--
-- The 'FromRow' typeclass, for converting a row of results
-- returned by a SQL query into a more useful Haskell representation.
--
-- Predefined instances are provided for tuples containing up to ten
-- elements.
------------------------------------------------------------------------------

module Database.PostgreSQL.Simple.FromRow
     ( FromRow(..)
     , RowParser
     , field
     , numFieldsRemaining
     ) where

import Control.Applicative (Applicative(..), (<$>))
import Control.Exception (SomeException(..), throw)
import Control.Monad (replicateM)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import Database.PostgreSQL.Simple.Internal
import Database.PostgreSQL.Simple.Types (Only(..))
import Database.PostgreSQL.Simple.Ok
import qualified Database.PostgreSQL.LibPQ as PQ
import           Database.PostgreSQL.Simple.Internal
import           Database.PostgreSQL.Simple.FromField

import Control.Monad.Trans.State.Strict
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Class

import Data.Vector ((!))

import System.IO.Unsafe ( unsafePerformIO )

class FromRow a where
    fromRow :: RowParser a

field :: FromField a => RowParser a
field = RP $ do
    let unCol (PQ.Col x) = fromIntegral x
    Row{..} <- ask
    column <- lift get
    lift (put (column + 1))
    let ncols = nfields rowresult
    if (column >= ncols)
    then do
        let vals = map (\c -> ( typenames ! (unCol c)
                              , fmap ellipsis (getvalue rowresult row c) ))
                       [0..ncols-1]
            convertError = ConversionFailed
                (show (unCol ncols) ++ " values: " ++ show vals)
                ("at least " ++ show (unCol column + 1)
                  ++ " slots in target type")
                "mismatch between number of columns to \
                \convert and number in target type"
        lift (lift (Errors [SomeException convertError]))
    else do
        let typename = typenames ! unCol column
            result = rowresult
            field = Field{..}
        lift (lift (fromField field (getvalue result row column)))

ellipsis :: ByteString -> ByteString
ellipsis bs
    | B.length bs > 15 = B.take 10 bs `B.append` "[...]"
    | otherwise        = bs

numFieldsRemaining :: RowParser Int
numFieldsRemaining = RP $ do
    Row{..} <- ask
    column <- lift get
    return $! (\(PQ.Col x) -> fromIntegral x) (nfields rowresult - column)

instance (FromField a) => FromRow (Only a) where
    fromRow = do
        !a <- field
        return (Only a)

instance (FromField a, FromField b) => FromRow (a,b) where
    fromRow = do
        !a <- field
        !b <- field
        return (a,b)

instance (FromField a, FromField b, FromField c) => FromRow (a,b,c) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        return (a,b,c)

instance (FromField a, FromField b, FromField c, FromField d) =>
    FromRow (a,b,c,d) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        return (a,b,c,d)

instance (FromField a, FromField b, FromField c, FromField d, FromField e) =>
    FromRow (a,b,c,d,e) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        return (a,b,c,d,e)

instance (FromField a, FromField b, FromField c, FromField d, FromField e,
          FromField f) =>
    FromRow (a,b,c,d,e,f) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        !f <- field
        return (a,b,c,d,e,f)

instance (FromField a, FromField b, FromField c, FromField d, FromField e,
          FromField f, FromField g) =>
    FromRow (a,b,c,d,e,f,g) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        !f <- field
        !g <- field
        return (a,b,c,d,e,f,g)

instance (FromField a, FromField b, FromField c, FromField d, FromField e,
          FromField f, FromField g, FromField h) =>
    FromRow (a,b,c,d,e,f,g,h) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        !f <- field
        !g <- field
        !h <- field
        return (a,b,c,d,e,f,g,h)

instance (FromField a, FromField b, FromField c, FromField d, FromField e,
          FromField f, FromField g, FromField h, FromField i) =>
    FromRow (a,b,c,d,e,f,g,h,i) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        !f <- field
        !g <- field
        !h <- field
        !i <- field
        return (a,b,c,d,e,f,g,h,i)

instance (FromField a, FromField b, FromField c, FromField d, FromField e,
          FromField f, FromField g, FromField h, FromField i, FromField j) =>
    FromRow (a,b,c,d,e,f,g,h,i,j) where
    fromRow = do
        !a <- field
        !b <- field
        !c <- field
        !d <- field
        !e <- field
        !f <- field
        !g <- field
        !h <- field
        !i <- field
        !j <- field
        return (a,b,c,d,e,f,g,h,i,j)

instance FromField a => FromRow [a] where
    fromRow = do
      n <- numFieldsRemaining
      replicateM n field
