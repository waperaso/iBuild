#!/bin/sh
# Rebuilds the API from /srv/ibuild/src and restarts it. nginx and certificates stay.
set -eu
cd /srv/ibuild
docker compose -f /srv/ibuild/docker-compose.yml up -d --build
docker compose -f /srv/ibuild/docker-compose.yml ps
