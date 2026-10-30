# Discourse's own web-only image: their launcher build of samples/web_only.yml (nginx, unicorn and
# sidekiq in one container, Postgres and Redis outside). The ESR line gets security fixes only.
FROM discourse/discourse:2026.7.4 AS discourse

# First boot only, after migrations: create the admin from DISCOURSE_ADMIN_EMAIL and
# DISCOURSE_ADMIN_PASSWORD, so no email round-trip is needed to get in (Railway only allows
# outbound SMTP on Pro). /shared is the volume, so the marker survives redeploys.
COPY railway-setup.rb /usr/local/share/railway/setup.rb
# nginx's stock default site would answer the healthcheck with a 404 instead of Discourse.
# 2026.7.4 ships the new `live` plugin (voice and video rooms) without the discourse_voice_assets
# gem it requires, so Rails can't load: drop the plugin until the image bundles the gem.
# Under 2 GB (Railway's Free and Trial plans) run one unicorn worker instead of two: two workers,
# Sidekiq and nginx use about 1 GB.
RUN rm -rf /etc/nginx/sites-enabled/default /var/www/discourse/plugins/live \
 && sed -i '/^cd \/var\/www\/discourse$/a m=$(cat /sys/fs/cgroup/memory.max 2>/dev/null); if [[ $m =~ ^[0-9]+$ ]] \&\& (( m < 2147483648 )); then export UNICORN_WORKERS=1; fi' \
    /etc/service/unicorn/run \
 && sed -i "/rake db:migrate' || exit 1/a [ -f /shared/.railway-setup-done ] || (su discourse -c 'bundle exec rails runner /usr/local/share/railway/setup.rb' && touch /shared/.railway-setup-done) || true" \
    /etc/service/unicorn/run \
 && grep -q railway-setup-done /etc/service/unicorn/run && grep -q UNICORN_WORKERS=1 /etc/service/unicorn/run

# One layer. The image's last layer deletes and reinstalls the gem bundle, and Railway flattens
# layers without applying deletions, so gems went missing and deleted files came back.
FROM scratch
COPY --from=discourse / /

# The upstream image's config, which FROM scratch drops, with two unicorn workers instead of three
# to stay near 1 GB. Every boot migrates the database and
# precompiles assets (about a minute), so bumping the tag is the whole upgrade.
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    RUBY_VERSION=4.0.9 PG_MAJOR=18 PG_MAJOR_OLD=15 RUBY_ALLOCATOR=/usr/lib/libjemalloc.so \
    LEFTHOOK=0 DEBIAN_RELEASE=trixie LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 \
    RAILS_ENV=production CREATE_DB_ON_BOOT=1 DISABLE_LETSENCRYPT=1 MIGRATE_ON_BOOT=1 \
    PRECOMPILE_ON_BOOT=1 RUBY_GC_HEAP_GROWTH_MAX_SLOTS=40000 RUBY_GC_HEAP_INIT_SLOTS=400000 \
    RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5 UNICORN_SIDEKIQS=1 UNICORN_WORKERS=2
EXPOSE 80
CMD ["/sbin/boot"]
