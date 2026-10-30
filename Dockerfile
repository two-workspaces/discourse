# Discourse's own web-only image: their launcher build of samples/web_only.yml (nginx, unicorn and
# sidekiq in one container, Postgres and Redis outside). The ESR line gets security fixes only.
FROM discourse/discourse:2026.7.4

# The image runs migrations on every boot (MIGRATE_ON_BOOT=1), which upgrades need. It also
# recompiles assets on every boot, although the launcher build already compiled them, so skip that.
# Two unicorn workers is what discourse-setup picks below 2 GB of RAM.
ENV PRECOMPILE_ON_BOOT=0 UNICORN_WORKERS=2

# First boot only, after migrations: create the admin from DISCOURSE_ADMIN_EMAIL and
# DISCOURSE_ADMIN_PASSWORD, so no email round-trip is needed to get in (Railway only allows
# outbound SMTP on Pro). /shared is the volume, so the marker survives redeploys.
COPY railway-setup.rb /usr/local/share/railway/setup.rb
COPY railway-boot.sh /etc/runit/1.d/00-railway
RUN sed -i "/rake db:migrate' || exit 1/a [ -f /shared/.railway-setup-done ] || (su discourse -c 'bundle exec rails runner /usr/local/share/railway/setup.rb' && touch /shared/.railway-setup-done) || true" \
    /etc/service/unicorn/run \
 && grep -q railway-setup-done /etc/service/unicorn/run
