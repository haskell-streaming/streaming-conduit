# Revision history for streaming-conduit

## 0.1.2.3

* Generalize the argument type of `toBStream`.

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
