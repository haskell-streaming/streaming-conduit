{-# LANGUAGE RankNTypes #-}

{- |
   Module      : Streaming.Conduit
   Description : Bidirectional support for the streaming and conduit libraries
   Copyright   : Ivan Lazar Miljenovic
   License     : MIT
   Maintainer  : Ivan.Miljenovic@gmail.com



 -}
module Streaming.Conduit where

import           Control.Monad             (join, void)
import           Control.Monad.Trans.Class (lift)
import           Data.Conduit              (Conduit, ConduitM, Producer, Source,
                                            await, runConduit, yield, (.|))
import qualified Data.Conduit.List         as CL
import           Streaming                 (Of, Stream, hoist)
import qualified Streaming.Prelude         as S

--------------------------------------------------------------------------------

-- | The result of this is slightly generic than a 'Source' or a
--   'Producer'.  If it fits in the types you want, you may wish to use
--   'fromStreamProducer' which is subject to fusion.
fromStream :: (Monad m) => Stream (Of a) m r -> ConduitM i a m r
fromStream = go
  where
    go stream = do eras <- lift (S.next stream)
                   case eras of
                     Left r             -> return r
                     Right (a, stream') -> yield a >> go stream'

-- | A type-specialised variant of 'fromStream' that ignores the
--   result.
fromStreamSource :: (Monad m) => Stream (Of a) m r -> Source m a
fromStreamSource = void . fromStream

-- | A more specialised variant of 'fromStream' that is subject to
--   fusion.
fromStreamProducer :: (Monad m) => Stream (Of a) m r -> Producer m a
fromStreamProducer = CL.unfoldM S.uncons . void

-- | Convert a 'Source' to a 'Stream'.  Subject to fusion.
toStream :: (Monad m) => Source m o -> Stream (Of o) m ()
toStream cnd = runConduit (cnd' .| mkStream)
  where
    mkStream = CL.mapM_ S.yield

    cnd' = hoist lift cnd

-- | Treat a 'Conduit' as a function between 'Stream's.  Subject to
--   fusion.
asStream :: (Monad m) => Conduit i m o -> Stream (Of i) m () -> Stream (Of o) m ()
asStream cnd stream = toStream (src .| cnd)
  where
    src = fromStreamProducer stream

-- | Treat a function between 'Stream's as a 'Conduit'.  May be
--   subject to fusion.
asConduit :: (Monad m) => (Stream (Of i) m () -> Stream (Of o) m r) -> Conduit i m o
asConduit f = join . fmap (fromStreamProducer . f) $ go
  where
    -- Probably not the best way to go about it,
    go = do mo <- await
            case mo of
              Nothing -> return (return ())
              Just o  -> S.cons o <$> go
