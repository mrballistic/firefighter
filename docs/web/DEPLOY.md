# Deploying the web page

`www/` is the page exactly as it ships to <https://mrballistic.com/crank-and-catch/>. It deploys the same way as the RAID calculator's page (`RaidCalculator2/.github/workflows/www.yml`): pushing a website tag runs `.github/workflows/www.yml`, which checks the site and `rsync`s `www/` to the server over SSH.

## How a deploy works

| | |
|---|---|
| **Trigger** | Pushing a `www-vMAJOR.MINOR.PATCH` tag. Plain `v*` tags are game releases and never deploy the site. |
| **Guards** | The commit must be on `main`; anything that writes must come from a `www-v*` tag; the deploy path must end in `/crank-and-catch`, because the sync uses `--delete` and the shared web root holds other sites. |
| **Verification** | `www/index.html`, the favicon, the apple-touch icon and the social preview image exist, and every local `src`, `href`, `srcset`, `poster` and CSS `url()` in the HTML and CSS points at a real file. |
| **Deploy** | `rsync --delete` over SSH as `raid-deploy`, the RAID page's unprivileged deploy user (same key, shared on purpose), which owns only `/var/www/html/raid` and `/var/www/html/crank-and-catch`, with a pinned host key. `.DS_Store` and `.playwright-mcp/` never ship. 10-minute timeout. |
| **Secrets** | `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS` in the repository's `website` environment, which admits only `www-v*` tags, so a run from a branch or a fork can't reach them. The repo is public, which is why this matters. |
| **Manual runs** | Dispatch **Deploy website** with `dry_run` on (the default) to list every file it would add, change or delete without writing. Dispatch it from a `www-v*` tag ref; the environment refuses anything else. |

## One-time setup

This reuses the RAID page's deploy setup: same server, same `raid-deploy` user, same key. **Status: done (2026-11-04).** The directory exists, both secrets are set, and `www-v1.0.0` deployed successfully. The steps below are kept for reference (e.g. rotating the key).

### 1. Give `raid-deploy` this site's directory (on the server, as an admin)

```bash
sudo install -d -m 755 -o raid-deploy -g raid-deploy /var/www/html/crank-and-catch
```

The web server already serves `/var/www/html/raid` at `/raid/`, so `/var/www/html/crank-and-catch` should appear at `/crank-and-catch/` with no web-server change.

### 2. Copy the RAID repo's two secrets into this repo (on your Mac)

**Easiest:** `scripts/setup_deploy_secrets.sh [path/to/private-key]` (default `~/.ssh/raid_deploy_crank`). It checks the key matches its `.pub`, that `raid-deploy` can log in and write to the site's directory, and that the server's host key matches the one your Mac already trusts, then sets both secrets. The manual equivalent:

GitHub secrets on a personal account belong to one repository and can't be read back, so the values have to be set again here. They are the same two values `RaidCalculator2`'s `website` environment holds:

```bash
export GH_TOKEN="$(gh auth token --user mrballistic)"
REPO=mrballistic/playdate-crank-and-catch

# The raid-deploy private key (wherever you keep it)
gh secret set SSH_PRIVATE_KEY --env website --repo $REPO < /path/to/raid-deploy-key

# The server's host key line (same host as the RAID page); compare the
# fingerprint with the one you trust
ssh-keyscan -t ed25519 132.148.79.144 > /tmp/known_hosts_web
ssh-keygen -lf /tmp/known_hosts_web
gh secret set SSH_KNOWN_HOSTS --env website --repo $REPO < /tmp/known_hosts_web
rm /tmp/known_hosts_web
```

If the `raid-deploy` private key no longer exists anywhere but GitHub, make a new pair, append its public half to `~raid-deploy/.ssh/authorized_keys` on the server (keeping the existing line), and use the new private key here:

```bash
ssh-keygen -t ed25519 -N "" -C "raid-deploy@github-actions (playdate-crank-and-catch)" -f ~/raid_deploy_crank
# on the server: append ~/raid_deploy_crank.pub to ~raid-deploy/.ssh/authorized_keys
gh secret set SSH_PRIVATE_KEY --env website --repo $REPO < ~/raid_deploy_crank && rm ~/raid_deploy_crank
```

## Releasing the page

1. Edit `www/index.html` (the design is `docs/web/BRIEF.md` plus `docs/web/HANDOFF.md`), run `python3 scripts/check_page.py`, and merge to `main`.
2. Tag and push; the push deploys:

   ```bash
   git tag -a www-v1.0.0 -m "Website: first release"
   git push origin www-v1.0.0
   ```

   To preview first, dispatch **Deploy website** with `dry_run` on from that tag ref and check the list, especially deletions.
3. If the link preview changed, re-scrape the URL in Facebook's Sharing Debugger or LinkedIn's Post Inspector; both cache previews.

## Troubleshooting

| Symptom | Cause |
|---|---|
| "missing www/index.html" | The page hasn't been added yet, or was renamed. |
| "broken reference: …" | A `src`/`href`/`poster`/`url()` points at a file that isn't in `www/`. The message names the page and the path. |
| "is not on main; refusing to deploy" | The tag was made on a branch. Merge first, then tag the merge commit. |
| A manual run is refused by its environment | It was dispatched from a branch. `website` admits only `www-v*` tags. |
| `Permission denied (publickey)` | `SSH_PRIVATE_KEY` isn't the `raid-deploy` key (or its public half isn't in `~raid-deploy/.ssh/authorized_keys`). |
| `rsync: … Permission denied` writing files | `/var/www/html/crank-and-catch` isn't owned by `raid-deploy` (setup step 1). |
| `Host key verification failed` | `SSH_KNOWN_HOSTS` doesn't match the server; rescan and compare the fingerprint. |
