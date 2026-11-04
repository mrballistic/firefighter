#!/usr/bin/env bash
# One-time setup for the website deploy (docs/web/DEPLOY.md, step 3): put the
# raid-deploy SSH key and the server's pinned host key into this repo's
# `website` environment.
#
#   scripts/setup_deploy_secrets.sh [path/to/private-key]
#       default key: ~/.ssh/raid_deploy_crank
#   SKIP_LOGIN_TEST=1 scripts/setup_deploy_secrets.sh   # skip the SSH write test
#
# Checks everything before writing anything:
#   1. the private key exists, has safe permissions and matches its .pub
#   2. gh can act as the personal account and the `website` environment exists
#   3. the key can log in as raid-deploy and write to the site's directory
#   4. the scanned host key matches the one this Mac already trusts
#      (asks before continuing if it can't confirm)
# Then sets SSH_PRIVATE_KEY and SSH_KNOWN_HOSTS and lists the environment's
# secrets. The private key is read from disk by gh; it is never printed.
set -euo pipefail

KEY="${1:-$HOME/.ssh/raid_deploy_crank}"
REPO="mrballistic/playdate-crank-and-catch"
GH_USER="mrballistic"
HOST="132.148.79.144"
DEPLOY_USER="raid-deploy"
DEPLOY_PATH="/var/www/html/crank-and-catch"
ENV_NAME="website"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n%s\n' "$*"; }

step "1. Deploy key"
[[ -f "$KEY" ]] || fail "No private key at $KEY (pass the path as the first argument)."
[[ -f "$KEY.pub" ]] || fail "No public key at $KEY.pub."
perms="$(stat -f %Lp "$KEY")"
[[ "$perms" == "600" || "$perms" == "400" ]] || fail "$KEY is mode $perms; run: chmod 600 \"$KEY\""
derived="$(ssh-keygen -y -f "$KEY" 2>/dev/null | awk '{print $1, $2}')" \
    || fail "$KEY isn't a readable private key (or has a passphrase; deploy keys must not)."
[[ "$derived" == "$(awk '{print $1, $2}' "$KEY.pub")" ]] || fail "$KEY doesn't match $KEY.pub."
ok "$KEY matches $KEY.pub ($(ssh-keygen -lf "$KEY.pub" | awk '{print $2}'))"

step "2. GitHub"
GH_TOKEN="$(gh auth token --user "$GH_USER" 2>/dev/null)" \
    || fail "gh isn't logged in as $GH_USER (run: gh auth login)."
export GH_TOKEN
gh api "repos/$REPO/environments/$ENV_NAME" --jq .name >/dev/null 2>&1 \
    || fail "The '$ENV_NAME' environment doesn't exist on $REPO."
policy="$(gh api "repos/$REPO/environments/$ENV_NAME/deployment-branch-policies" \
    --jq '[.branch_policies[] | "\(.type):\(.name)"] | join(",")')"
[[ "$policy" == "tag:www-v*" ]] || fail "'$ENV_NAME' should admit only tag:www-v*, but has: ${policy:-nothing}"
ok "Acting as $GH_USER; '$ENV_NAME' on $REPO admits only www-v* tags"

step "3. Server login and write test"
if [[ "${SKIP_LOGIN_TEST:-}" == "1" ]]; then
    echo "  (skipped)"
else
    probe="$DEPLOY_PATH/.deploy-probe-$$"
    if ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
           "$DEPLOY_USER@$HOST" "touch '$probe' && rm '$probe'" 2>/tmp/deploy-probe-err; then
        ok "$DEPLOY_USER can log in and write to $DEPLOY_PATH"
    else
        sed 's/^/    /' /tmp/deploy-probe-err >&2
        rm -f /tmp/deploy-probe-err
        fail "Login or write failed. Is the .pub in ~$DEPLOY_USER/.ssh/authorized_keys, and is $DEPLOY_PATH owned by $DEPLOY_USER? (DEPLOY.md steps 1-2)"
    fi
    rm -f /tmp/deploy-probe-err
fi

step "4. Server host key"
KH="$(mktemp)"
trap 'rm -f "$KH"' EXIT
ssh-keyscan -t ed25519 -T 10 "$HOST" 2>/dev/null > "$KH"
[[ -s "$KH" ]] || fail "ssh-keyscan got no ed25519 key from $HOST."
# Take the SHA256 field wherever it is: `ssh-keygen -lf` prints
# "256 SHA256:… host (ED25519)" but `ssh-keygen -lF` prints "host ED25519 SHA256:…".
fingerprint() { grep -o 'SHA256:[A-Za-z0-9+/=]*' | head -1; }
scanned="$(ssh-keygen -lf "$KH" | fingerprint)"
trusted="$(ssh-keygen -lF "$HOST" 2>/dev/null | grep -i 'ED25519' | fingerprint || true)"
[[ -n "$scanned" ]] || fail "Couldn't read a fingerprint from the scanned key."
echo "  scanned now:      $scanned"
echo "  trusted by Mac:   ${trusted:-(none saved for $HOST)}"
if [[ -n "$trusted" && "$scanned" == "$trusted" ]]; then
    ok "Host key matches the one this Mac already trusts"
elif [[ -n "$trusted" ]]; then
    fail "Host key MISMATCH. Don't pin it; find out why the server's key changed first."
else
    read -r -p "  This Mac has no saved ed25519 key for $HOST to compare. Pin the scanned key anyway? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || fail "Stopped; nothing was changed."
fi

step "5. Setting secrets on $REPO ($ENV_NAME)"
gh secret set SSH_PRIVATE_KEY --env "$ENV_NAME" --repo "$REPO" < "$KEY"
ok "SSH_PRIVATE_KEY"
gh secret set SSH_KNOWN_HOSTS --env "$ENV_NAME" --repo "$REPO" < "$KH"
ok "SSH_KNOWN_HOSTS"

step "Secrets now in '$ENV_NAME':"
gh secret list --env "$ENV_NAME" --repo "$REPO" | sed 's/^/  /'

cat <<EOF

Done. Next: merge to main, then
  git tag -a www-v1.0.0 -m "Website: first release" && git push origin www-v1.0.0
The private key is still at $KEY; GitHub now has its own copy.
EOF
