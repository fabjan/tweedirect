# Tweedirect

Tweedirect redirects tweet links to their embed page.

## Requirements

* [Poly/ML] or [MLton]

[Poly/ML]: https://www.polyml.org
[MLton]: http://mlton.org

## Building

A local build:
```
./build.sh
```

Build a container image:
```
podman build . -t tweedirect
```

## Running

A local build:
```
TWEEDIRECT_HOST=localhost _build/tweedirect
```

A container:
```
podman run --rm -it -p3000:3000 -eTWEEDIRECT_HOST=localhost tweedirect
```

Connect a client:
```
curl http://localhost:3000
```
