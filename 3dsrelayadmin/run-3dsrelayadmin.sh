#!/bin/sh

# Error if non-true result
set -e

# Error on unset variables
set -u

echo Running turnadmin
exec turnadmin "$@"
