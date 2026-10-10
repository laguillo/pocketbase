# Deploy and Host Pocketbase on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/73ofk1?referralCode=HKQvZr&utm_medium=integration&utm_source=template&utm_campaign=generic)

PocketBase is an open source backend packed into a single Go binary. It bundles an embedded SQLite database with realtime subscriptions, user authentication with OAuth2, file storage, an auto-generated REST API, and an admin dashboard — replacing the database, auth provider, file bucket, and API server you would otherwise wire together yourself.

## About Hosting Pocketbase

Hosting PocketBase means running a single container with a persistent volume attached. The SQLite database, uploaded files, and instance settings all live in one directory, so the job is keeping that directory intact across restarts and redeploys. This template mounts a Railway volume at `/pb/pb_data` and points PocketBase at it explicitly, builds the image from the included Dockerfile, assigns a public HTTPS domain, and restarts the container if it fails. There is no reverse proxy to configure and no TLS certificate to renew. PocketBase uses SQLite on a single volume, so run one replica and scale vertically.

## Common Use Cases

- **Mobile and web app backends** — pair with the official JavaScript or Dart/Flutter SDK for realtime data sync, authentication, and file uploads without writing server code.
- **MVPs and small SaaS products** — stand up auth, a database, and file storage in minutes, without separate database, cache, and API services.
- **Internal tools and admin panels** — manage records directly from the built-in dashboard instead of building a custom CRUD interface.

## Dependencies for Pocketbase Hosting

- **A Railway persistent volume** — pre-configured by this template and mounted at `/pb/pb_data`. Without it, all data is lost on every redeploy.
- **An SMTP provider** (optional) — PocketBase has no mail server built in. Email verification and password resets need credentials from a provider such as Resend, Postmark, or Amazon SES.
- **S3-compatible storage** (optional) — for off-volume backups or file storage: AWS S3, Cloudflare R2, Backblaze B2, or MinIO.

### Implementation Details

**Getting started after deploy**

1. Open the service's **Deploy Logs** and find the line starting with `(!) Launch the URL below in the browser…`. It prints a link ending in `/_/#/pbinstall/<token>`.
2. Replace everything before `/_/` with your public domain and open it within 30 minutes, e.g. `https://your-app.up.railway.app/_/#/pbinstall/<token>`. Create your superuser there. If the token expired, restart the service to get a new one.
3. Create a collection. Its REST endpoints exist immediately.

Opening `/_/` without the token shows the login page, not a setup screen. Prefer the CLI? Run `railway ssh`, then:

```
/pb/pocketbase superuser upsert you@example.com a-strong-password --dir=/pb/pb_data
```

If no public URL appears, open the service's Settings → Networking and click Generate Domain.

**Configuration**

Every variable is optional; the template runs with none of them set.

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | Port PocketBase listens on. Railway sets it automatically. |
| `PB_VERSION` | `0.40.5` | Build argument. Add it as a service variable to build a different PocketBase release without editing the Dockerfile. |
| `PB_ENCRYPTION_KEY` | unset | Exactly 32 characters. When present, PocketBase encrypts stored settings at rest. |

SMTP, OAuth providers, backup schedules, and S3 storage are configured in the admin dashboard, not through environment variables.

SMTP passwords and OAuth client secrets are stored in plain text unless `PB_ENCRYPTION_KEY` is set. You can enable it after the first deploy; settings are encrypted the next time they are saved. **Keep the key safe: if it is lost or removed after settings were encrypted, PocketBase will not start.** When the key is set, add `--encryptionEnv=PB_ENCRYPTION_KEY` to any CLI command you run in the shell.

The health check path is `/api/health` (set in `railway.toml`). Railway waits for it to pass before switching traffic to a new deployment. Because a volume can only be mounted once, redeploys have a brief downtime.

**Where your data lives**

```
/pb/pb_data/
├── data.db          # collections, records, users
├── auxiliary.db     # logs
├── storage/         # uploaded files
└── backups/         # local backups created from the dashboard
```

Three extension directories sit alongside it: `/pb/pb_hooks` for JavaScript hooks, `/pb/pb_migrations` for schema migrations, and `/pb/pb_public` for static files served at the root of your domain.

**Backups**

A volume is not a backup. Use Settings → Backups in the admin dashboard to create backups on demand, set a cron schedule, choose how many to keep, and restore any of them. The schedule runs in **UTC** and is not affected by `TZ`: `0 3 * * *` is 3am UTC, so use `0 8 * * *` for 3am in Bogotá.

Backups are written to the same volume by default, which protects against a bad migration but not against losing the volume. For real durability, enable S3 storage for backups in the same settings screen.

**Connecting your app**

```js
import PocketBase from 'pocketbase';

const pb = new PocketBase('https://your-app.up.railway.app');

await pb.collection('users').authWithPassword('user@example.com', 'password');

const posts = await pb.collection('posts').getList(1, 20, {
  filter: 'published = true',
  sort: '-created',
});

pb.collection('posts').subscribe('*', (e) => {
  console.log(e.action, e.record);
});
```

Official SDKs: [JavaScript/TypeScript](https://github.com/pocketbase/js-sdk) and [Dart/Flutter](https://github.com/pocketbase/dart-sdk). Realtime subscriptions in Node.js need an `EventSource` polyfill.

**Upgrading**

PocketBase is pre-`v1.0.0` and ships releases often, so full backward compatibility is not guaranteed and this template pins a version instead of tracking latest. To upgrade: read the [changelog](https://github.com/pocketbase/pocketbase/releases), take a backup, set `PB_VERSION` to the new release number without the leading `v`, and redeploy. Rolling back is the same operation in reverse, plus restoring the backup if the newer version already migrated your database.

**Troubleshooting**

- *The dashboard returns 404.* The admin UI lives at `/_/`, not at the root.
- *Lost superuser password.* Run `railway ssh`, then `/pb/pocketbase superuser upsert your@email.com newpassword --dir=/pb/pb_data` (add `--encryptionEnv=PB_ENCRYPTION_KEY` if you set that variable).
- *Files disappeared after a redeploy.* Confirm the volume is still mounted at `/pb/pb_data`. If the mount path changed, PocketBase wrote to the container's ephemeral filesystem.
- *Emails aren't sending.* Configure SMTP under Settings → Mail settings. Failures are logged in the deploy logs.
- *Backups run at the wrong hour.* The schedule is always UTC; convert your local time.

## Why Deploy Pocketbase on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Pocketbase on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
