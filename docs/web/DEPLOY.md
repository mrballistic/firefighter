# Deploying the web page

`www/` is the page exactly as it ships to <https://mrballistic.com/crank-and-catch/>. It deploys the same way as the RAID calculator's page (`RaidCalculator2/.github/workflows/www.yml`): pushing a website tag runs `.github/workflows/www.yml`, which checks the site and `rsync`s `www/` to the server over SSH.

## How a deploy works

| | |
|---|---|
| **Trigger** | Pushing a `www-vMAJOR.MINOR.PATCH` tag. Plain `v*` tags are game releases and never deploy the site. |
| **Guards** | The commit must be on `main`; anything that writes must come from a `www-v*` tag; the deploy path must end in `/crank-and-catch`, because the sync uses `--delete` and the shared web root holds other sites. |
| **Verification** | `www/index.html`, the favicon, the apple-touch icon and the social preview image exist, and every local `src`, `href`, `srcset`, `poster` and CSS `url()` in the HTML and CSS points at a real file. |
| **Deploy** | `rsync --delete` over SSH as `crank-deploy`, an unprivileged user that owns only `/var/www/html/crank-and-catch`, with a pinned host key. `.DS_Store` and `.playwright-mcp/` never ship. 10-minute timeout. |
| **Secrets** | `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS` in the repository's `website` environment, which admits only `www-v*` tags, so a run from a branch or a fork can't reach them. The repo is public, which is why this matters. |
| **Manual runs** | Dispatch **Deploy website** with `dry_run` on (the default) to list every file it would add, change or delete without writing. Dispatch it from a `www-v*` tag ref; the environment refuses anything else. |

## One-time setup

Status: the `website` environment exists and admits only `www-v*` tags. The server user, the deploy key and the two secrets still need doing.

### 1. Make a deploy key (on your Mac)

```bash
ssh-keygen -t ed25519 -N "" -C "crank-deploy@github-actions (mrballistic/playdate-crank-and-catch)" -f ~/crank_deploy
cat ~/crank_deploy.pub   # the public half, for step 2
```

### 2. Create the deploy user and directory (on the server, as an admin)

Same pattern as `raid-deploy`: no sudo, owns only its site's directory.

```bash
sudo useradd -m -s /bin/bash crank-deploy
sudo install -d -m 755 -o crank-deploy -g crank-deploy /var/www/html/crank-and-catch
sudo install -d -m 700 -o crank-deploy -g crank-deploy ~crank-deploy/.ssh
echo 'PASTE THE CONTENTS OF ~/crank_deploy.pub HERE' | sudo tee ~crank-deploy/.ssh/authorized_keys >/dev/null
sudo chown crank-deploy:crank-deploy ~crank-deploy/.ssh/authorized_keys
sudo chmod 600 ~crank-deploy/.ssh/authorized_keys
```

The web server already serves `/var/www/html/raid` at `/raid/`, so `/var/www/html/crank-and-catch` should appear at `/crank-and-catch/` with no web-server change. If the server only allows SSH logins for specific users (`AllowUsers` or `AllowGroups` in `sshd_config`), add `crank-deploy` the same way `raid-deploy` was added.

### 3. Add the two secrets (on your Mac)

```bash
export GH_TOKEN="$(gh auth token --user mrballistic)"
REPO=mrballistic/playdate-crank-and-catch

# The private key
gh secret set SSH_PRIVATE_KEY --env website --repo $REPO < ~/crank_deploy

# The server's host key, pinned. Compare the fingerprint with the one you
# trust for this server (it's the same host as the RAID page).
ssh-keyscan -t ed25519 132.148.79.144 > /tmp/crank_known_hosts
ssh-keygen -lf /tmp/crank_known_hosts
gh secret set SSH_KNOWN_HOSTS --env website --repo $REPO < /tmp/crank_known_hosts

# The private key now lives only in GitHub
rm ~/crank_deploy /tmp/crank_known_hosts
```

### 4. Test the login (optional, on your Mac, before deleting the key)

```bash
ssh -i ~/crank_deploy crank-deploy@132.148.79.144 'pwd; ls -ld /var/www/html/crank-and-catch'
```

## Releasing the page

1. Put the page at `www/index.html` (from Claude Design; see `docs/web/BRIEF.md`) and merge to `main`.
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
| `Permission denied (publickey)` | The public key isn't in `~crank-deploy/.ssh/authorized_keys`, its permissions are too open, or `sshd` doesn't allow the user. |
| `Host key verification failed` | `SSH_KNOWN_HOSTS` doesn't match the server; rescan and compare the fingerprint. |
