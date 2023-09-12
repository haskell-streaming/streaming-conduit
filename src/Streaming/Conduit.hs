{-# LANGUAGE RankNTypes #-}

{- |
   Module      : Streaming.Conduit
   Description : Bidirectional support for the streaming and conduit libraries
   Copyright   : Ivan Lazar Miljenovic
   License     : MIT
   Maintainer  : Ivan.Miljenovic@gmail.com


  This provides interoperability between the
  <http://hackage.haskell.org/package/streaming streaming> and
  <http://hackage.haskell.org/package/conduit conduit> libraries.

  Not only can you convert between one streaming data representation
  to the other, there is also support to use one in the middle of a
  pipeline.

  No 'B.ByteString'-based analogues of 'asConduit' and 'asStream' are
  provided as it would be of strictly less utility, requiring both the
  input and output of the 'ConduitT' to be 'ByteString'.

 -}
module Streaming.Conduit
  ( -- * Converting from Streams
    fromStream
  , fromStreamSource
  , fromStreamProducer
  , asConduit
    -- ** ByteString support
  , fromBStream
  , fromBStreamProducer
    -- * Converting from Conduits
  , toStream
  , asStream
  , sinkStream
    -- ** ByteString support
  , toBStream
  , sinkBStream
  ) where

import           Control.Monad             (join, void)
import           Control.Monad.Trans.Class (lift)
import           Data.ByteString           (ByteString)
import qualified Data.ByteString.Streaming as B
import           Data.Conduit              (Conduit, ConduitT, Producer, Consumer,
                                            await, runConduit, transPipe, (.|))
import qualified Data.Conduit.List         as CL
import           Streaming                 (Of, Stream)
import qualified Streaming.Prelude         as S

--------------------------------------------------------------------------------

-- | The result of this is slightly generic than a 'Source' or a
--   'Producer'.  Subject to fusion.
fromStream :: (Monad m) => Stream (Of o) m r -> ConduitT i o m r
fromStream = CL.unfoldEitherM S.next

-- | A type-specialised variant of 'fromStream' that ignores the
--   result.
--
-- It can return a Conduit @Source@:
-- @
-- fromStreamSource :: (Monad m) => Stream (Of o) m r -> Source m o
-- @
fromStreamSource :: (Monad m) => Stream (Of o) m r -> ConduitT () o m ()
fromStreamSource = void . fromStream

-- | A more specialised variant of 'fromStream' that is subject to
--   fusion.
--
-- It can return a Conduit @Producer@:
-- @
-- fromStreamProducer :: (Monad m) => Stream (Of a) m r -> Producer m a
-- @
fromStreamProducer :: (Monad m) => Stream (Of o) m r -> ConduitT i o m r
fromStreamProducer = CL.unfoldEitherM S.next

-- | Convert a streaming 'B.ByteString' into a 'Source'; subject to fusion.
fromBStream :: (Monad m) => B.ByteString m r -> ConduitT i ByteString m r
fromBStream = CL.unfoldEitherM B.nextChunk

-- | A more specialised variant of 'fromBStream'.
--
-- It can return a Conduit @Producer@:
-- @
-- fromBStreamProducer :: (Monad m) => B.ByteString m r -> Producer m ByteString
-- @
fromBStreamProducer :: (Monad m) => B.ByteString m r -> ConduitT i ByteString m r
fromBStreamProducer = CL.unfoldEitherM B.unconsChunk

-- | Convert a 'Producer' to a 'Stream'.  Subject to fusion.
--
--   It is not possible to generalise this to be a 'ConduitT' as input
--   values are required.  If you need such functionality, see
--   'asStream'.
toStream :: (Monad m) => Producer m o -> Stream (Of o) m ()
toStream cnd = runConduit (transPipe lift cnd .| CL.mapM_ S.yield)

-- | Convert a 'Producer' to a 'B.ByteString' stream.  Subject to
--   fusion.
toBStream :: (Monad m) => Producer m ByteString -> B.ByteString m ()
toBStream cnd = runConduit (transPipe lift cnd .| CL.mapM_ B.chunk)

-- | Treat a 'Conduit' as a function between 'Stream's.  Subject to
--   fusion.
asStream :: (Monad m) => Conduit i m o -> Stream (Of i) m () -> Stream (Of o) m ()
asStream cnd stream = toStream (fromStream stream .| cnd)

-- | Treat a 'Consumer' as a function which consumes a 'Stream'.
--   Subject to fusion.
sinkStream :: (Monad m) => Consumer i m r -> Stream (Of i) m () -> m r
sinkStream cns stream = runConduit (fromStream stream .| cns)

-- | Treat a 'Consumer' as a function which consumes a 'B.ByteString'.
--   Subject to fusion.
sinkBStream :: (Monad m) => Consumer ByteString m r -> B.ByteString m () -> m r
sinkBStream cns stream = runConduit (fromBStream stream .| cns)

-- | Treat a function between 'Stream's as a 'Conduit'.  May be
--   subject to fusion.
asConduit :: (Monad m) => (Stream (Of i) m () -> Stream (Of o) m r) -> ConduitT i o m r
asConduit f = join . fmap (fromStream . f) $ go
  where
    -- Probably not the best way to go about it, but it works.
    go = do mo <- await
            case mo of
              Nothing -> return (return ())
              Just o  -> S.cons o <$> go
