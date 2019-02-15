#!/bin/bash

set -u

[[ $DEBUG == true ]] && set -x

exec "$@"
