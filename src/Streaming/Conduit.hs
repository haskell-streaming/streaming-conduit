{-# LANGUAGE RankNTypes #-}

{- |
   Module      : Streaming.Conduit
   Description : Bidirectional support for the streaming and conduit libraries
   Copyright   : Ivan Lazar Miljenovic
   License     : MIT
   Maintainer  : Ivan.Miljenovic@gmail.com



 -}
module Streaming.Conduit where

import           Control.Monad             (void)
import           Control.Monad.Trans.Class (lift)
import           Data.Conduit              (ConduitM, Producer, Source, yield)
import           Data.Conduit.List         (unfoldM)
import           Streaming                 (Of, Stream)
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
fromStreamProducer = unfoldM S.uncons . void
