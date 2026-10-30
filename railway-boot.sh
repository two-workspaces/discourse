#!/bin/bash
# Runs at boot from /etc/runit/1.d. Railway flattens image layers and drops deletions, so files
# removed in the Dockerfile come back: remove them here instead.
# nginx's stock default site would answer the healthcheck with a 404 instead of Discourse.
rm -f /etc/nginx/sites-enabled/default
# 2026.7.4 ships the new `live` plugin (voice and video rooms) without the discourse_voice_assets
# gem it requires, so Rails can't load. Drop the plugin until the image bundles the gem.
rm -rf /var/www/discourse/plugins/live
