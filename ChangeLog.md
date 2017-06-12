# Revision history for streaming-conduit

## 0.1.2.0 -- 2017-06-12

* Better Stream -> Conduit conversions, allowing for more fusion and
  more generic return values (specifically, `fromBStream` and
  `asConduit` have been generalised in the return type of the
  resulting `Conduit`).

## 0.1.1.0 -- 2017-06-08

* Add support for streaming ByteStrings

## 0.1.0.0  -- 2017-06-08

* Initial release
