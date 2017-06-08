streaming-conduit
=================

[![Hackage](https://img.shields.io/hackage/v/streaming-conduit.svg)](https://hackage.haskell.org/package/streaming-conduit) [![Build Status](https://travis-ci.org/ivan-m/streaming-conduit.svg)](https://travis-ci.org/ivan-m/streaming-conduit)

Bidirectional support between the [streaming] and [conduit] libraries.

[streaming]: http://hackage.haskell.org/package/streaming
[conduit]: http://hackage.haskell.org/package/conduit

Motivation
----------

The streaming library provides a rather elegant model of how to stream
data, with libraries providing support for features like
[`ByteString`s], [PostgreSQL], [network requests] and others.

[`ByteString`s]: http://hackage.haskell.org/package/streaming-bytestring
[PostgreSQL]: http://hackage.haskell.org/package/streaming-postgresql-simple
[network requests]: http://hackage.haskell.org/package/streaming-wai

However, there are various other libraries you may wish to use that
represent data streaming as a `Conduit`.

This library provides support to convert between these two models.
