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
import           Data.Conduit              (ConduitT,
                                            await, runConduit, transPipe, (.|))
import qualified Data.Conduit.List         as CL
import           Data.Void                 (Void)
import           Streaming                 (Of, Stream)
import           Streaming.ByteString      (ByteStream)
import qualified Streaming.ByteString      as B
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
fromBStream :: (Monad m) => ByteStream m r -> ConduitT i ByteString m r
fromBStream = CL.unfoldEitherM B.unconsChunk

-- | A more specialised variant of 'fromBStream'.
--
-- It can return a Conduit @Producer@:
-- @
-- fromBStreamProducer :: (Monad m) => ByteStream m r -> Producer m ByteString
-- @
fromBStreamProducer :: (Monad m) => ByteStream m r -> ConduitT i ByteString m r
fromBStreamProducer = CL.unfoldEitherM B.unconsChunk

-- | Convert a 'Producer' to a 'Stream'.  Subject to fusion.
--
--   It is not possible to generalise this to be a 'ConduitT' as input
--   values are required.  If you need such functionality, see
--   'asStream'.
--
-- It can accept a Conduit @Producer@:
-- @
-- toStream :: (Monad m) => Producer m o -> Stream (Of o) m ()
-- @
toStream :: (Monad m) => ConduitT () o m () -> Stream (Of o) m ()
toStream cnd = runConduit (transPipe lift cnd .| CL.mapM_ S.yield)

-- | Convert a 'Producer' to a 'ByteStream' stream.  Subject to
--   fusion.
--
-- It can accept a Conduit @Producer@:
-- @
-- toBStream :: (Monad m) => Producer m ByteString -> ByteStream m ()
-- @
toBStream :: (Monad m) => ConduitT () ByteString m () -> ByteStream m ()
toBStream cnd = runConduit (transPipe lift cnd .| CL.mapM_ B.chunk)

-- | Treat a 'Conduit' as a function between 'Stream's.  Subject to
--   fusion.
asStream :: (Monad m) => ConduitT i o m () -> Stream (Of i) m () -> Stream (Of o) m ()
asStream cnd stream = toStream (fromStream stream .| cnd)

-- | Treat a 'Consumer' as a function which consumes a 'Stream'.
--   Subject to fusion.
--
-- It can accept a Conduit @Consumer@:
-- @
-- sinkStream :: (Monad m) => Consumer i m r -> Stream (Of i) m () -> m r
-- @
sinkStream :: (Monad m) => ConduitT i Void m r -> Stream (Of i) m () -> m r
sinkStream cns stream = runConduit (fromStream stream .| cns)

-- | Treat a 'Consumer' as a function which consumes a 'ByteStream'.
--   Subject to fusion.
--
-- It can accept a Conduit @Consumer@:
-- @
-- sinkBStream :: (Monad m) => Consumer ByteString m r -> ByteStream m () -> m r
-- @
sinkBStream :: (Monad m) => ConduitT ByteString Void m r -> ByteStream m () -> m r
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
