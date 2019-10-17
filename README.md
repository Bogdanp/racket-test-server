# Racket Test Server

This project tests a Racket web server making many synchronous
requests under a hard deadline.

The server accepts a request on the `/numbers` endpoint with various
`?u` query parameters.  It then performs a GET request on each
endpoint obtaining a JSON list of numbers and aggregates all the
results.

The application must always return a response under 500ms, even if it
couldn't get any numbers.

## Running the example

You need [go] and [vegeta].

In three separate terminal windows, run:

1. `go run numberserver.go`
2. `env PLT_INCREMENTAL_GC=1 racket server.rkt`
3. `./loadtest.sh targets-flawed results-flawed.bin plot-flawed.html`
3. `./loadtest.sh targets results.bin plot.html`

To find out how to tweak the load test, read [vegeta]'s documentation.

## Acknowledgements

This project was originally created by [@zkry](https://github.com/zkry).

[go]: https://golang.org
[vegeta]: https://github.com/tsenart/vegeta
