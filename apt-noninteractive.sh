#!/bin/sh 

# Used by tbxsos-configd to execute apt-bundle and apt-get in
# non-interactive mode.

# This is a hack to compensate for the lack of ruby implementation of
# execve.

DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical $@