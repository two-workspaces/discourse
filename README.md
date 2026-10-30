# Deploy and Host Discourse on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/discourse-community?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=discourse-community)

[Discourse](https://www.discourse.org/) is the open-source community forum: threaded discussions with live updates, trust levels that hand moderation to your regulars, chat, search, single sign-on, and hundreds of plugins and themes. This template runs Discourse's own image on the ESR (extended support) release and creates your admin account on first boot, so you can log in without setting up email first.

## About Hosting Discourse

The stack is three services: Discourse, Postgres and Redis.

- **The official image, on the stable line.** Discourse's web-only image runs nginx, the Rails server and the Sidekiq background workers in one service. It's pinned to the ESR release, which gets security fixes for a year without feature churn.
- **Admin ready on boot.** The first boot migrates the database and creates an admin from your email and a generated password. No confirmation email, no mock mail server: three services, not four.
- **Upgrades that migrate themselves.** Every boot runs Discourse's migrations and asset build before serving, so bumping the image tag is the whole upgrade.
- **Private by default.** Only nginx has a public address. Postgres and Redis are on the private network, and both require a password.

## Common Use Cases

- A community forum for an open-source project, product or creator audience
- A customer support and feedback forum that search engines can index
- An internal knowledge and discussion board for a company or club

## Dependencies for Discourse Hosting

- Postgres 18 (included, private network only)
- Redis 8 (included, private network only)

### Deployment Dependencies

- [Discourse admin guide](https://meta.discourse.org/c/documentation/admins/)
- [Discourse on GitHub](https://github.com/discourse/discourse)
- [Template source on GitHub](https://github.com/two-workspaces/discourse)

### Implementation Details

**Sign in** at the Discourse service's Railway domain with the email you entered at deploy time and the `DISCOURSE_ADMIN_PASSWORD` value from the Discourse service's Variables tab. The first boot creates the database and builds assets, so give it three to five minutes. Change the password afterwards in your profile's preferences; the variable is only read on first boot.

**Email.** Discourse works without email for the admin, but new members confirm their accounts by email, and notifications and digests go out by email. Railway only allows outbound SMTP on the Pro plan. Set `DISCOURSE_SMTP_ADDRESS`, `DISCOURSE_SMTP_USER_NAME`, `DISCOURSE_SMTP_PASSWORD` and `DISCOURSE_NOTIFICATION_EMAIL` on the Discourse service with any transactional provider (Postmark, Mailgun, SES, Brevo) and redeploy. Until then, you can invite members and approve them by hand from the admin panel.

**Memory.** Around 1.2 GB at idle: about 1 GB for the Discourse service (two web workers, Sidekiq and nginx), 200 MB for Postgres and a few MB for Redis. Hobby or above is the comfortable fit. Under a 2 GB limit the template starts one web worker instead of two, so it also boots on a 1 GB plan, though a busy forum will want more. To scale up, raise `UNICORN_WORKERS` on the Discourse service.

**Uploads and backups.** Uploads, avatars and Discourse's own backups live on the Discourse service's volume at `/shared`, and posts live in Postgres. Enable Railway's volume backups on both, or schedule Discourse's backups under Admin → Backups.

**Custom domain.** Add it in the Discourse service's Settings → Networking, then set `DISCOURSE_HOSTNAME` to the bare domain (`forum.example.com`). Discourse uses it in links and emails after the next deploy. To rewrite links in old posts, run `rake posts:rebake` in a `railway ssh` session.

**Plugins.** The image comes with Discourse's bundled plugins (chat, solved, polls, AI and more), enabled under Admin → Plugins. Third-party plugins are installed at image build time, so they need a fork of the template repository.

## Why Deploy Discourse on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Discourse on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
