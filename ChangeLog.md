# Revision history for streaming-conduit

## Unreleased (Minor) -- YYYY-MM-DD

* Generalise the return types of `toStream` and `toBStream` to return
  the conduit's return type:

  ```
  Old: toStream :: (Monad m) => ConduitT () o m () -> Stream (Of o) m ()
  New: toStream :: (Monad m) => ConduitT () o m r  -> Stream (Of o) m r

  Old: toBStream :: (Monad m) => ConduitT () ByteString m () -> ByteStream m ()
  New: toBStream :: (Monad m) => ConduitT () ByteString m r  -> ByteStream m r
  ```

* Stop referring to deprecated names in `conduit` and `streaming-bytestring`.
* Support GHC 9.0.

## 0.1.3.0 -- 2023-05-13

* Support `streaming-bytestring-0.3`

## 0.1.2.2 -- 2018-02-11

* Add support for conduit-1.3.0.

## 0.1.2.1 -- 2018-02-08

* Bump dependency on streaming to support 0.2.0.0.

## 0.1.2.0 -- 2017-06-12

* Better Stream -> Conduit conversions, allowing for more fusion and
  more generic return values (specifically, `fromBStream` and
  `asConduit` have been generalised in the return type of the
  resulting `Conduit`).

## 0.1.1.0 -- 2017-06-08

* Add support for streaming ByteStrings

## 0.1.0.0  -- 2017-06-08

* Initial release
