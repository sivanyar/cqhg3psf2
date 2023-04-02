#!/usr/bin/env pwsh

& docker run -it --rm -v $PSScriptRoot/src:/src -w /src ps2dev/ps2dev:v1.2.0 sh -c "apk add make && make $args"
