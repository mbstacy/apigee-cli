# apigee-push

A single-file CLI tool to bundle, upload, and deploy Apigee X proxy and shared flow bundles — all in one command.

Automatically detects bundle type (`apiproxy` vs `sharedflowbundle`) and name from the folder structure, authenticates via a service account key or your active `gcloud` session, and deploys to any environment.

---

## Features

- Zips, uploads, and deploys in one step
- Auto-detects bundle type and name from XML descriptor
- Supports proxies and shared flows
- Per-environment org and SA key config via `~/.apigee-push`
- `--all` flag to process every bundle in the current directory
- `--download` to pull a revision from Apigee back to local
- `--yes` for non-interactive use (CI, scripting, Claude Code skill)

---

## Requirements

- `bash` 4+
- [`gcloud`](https://cloud.google.com/sdk/docs/install) (for authentication)
- `curl`
- `jq`
- `zip` / `unzip`

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/markstacy/apigee-push/main/apigee-push -o ~/local/bin/apigee-push
chmod +x ~/local/bin/apigee-push
```

Or clone and symlink:

```bash
git clone https://github.com/markstacy/apigee-push.git ~/github/apigee-push
ln -sf ~/github/apigee-push/apigee-push ~/local/bin/apigee-push
```

Make sure `~/local/bin` is in your `PATH`:

```bash
# Add to ~/.zshrc or ~/.bashrc if not already there
export PATH="$HOME/local/bin:$PATH"
```

---

## Configuration

Create `~/.apigee-push` with your org names and service account key paths per environment:

```bash
DEV_ORG=my-nonprod-org
DEV_SA_KEY=$HOME/.ssh/apigee/nonprod.json

TEST_ORG=my-nonprod-org
TEST_SA_KEY=$HOME/.ssh/apigee/nonprod.json

SAND_ORG=my-nonprod-org
SAND_SA_KEY=$HOME/.ssh/apigee/nonprod.json

STAGE_ORG=my-preprod-org
STAGE_SA_KEY=$HOME/.ssh/apigee/preprod.json

PROD_ORG=my-prod-org
PROD_SA_KEY=$HOME/.ssh/apigee/prod.json
```

All values can be overridden per-run with `-o/--org` or `-k/--sa-key`.

If no SA key is configured, `apigee-push` falls back to your active `gcloud` session (`gcloud auth print-access-token`).

---

## Usage

```
apigee-push [OPTIONS] [FOLDER_NAME ...]
```

### Options

| Flag | Description |
|------|-------------|
| `-u, --upload` | Upload bundle(s) to Apigee after zipping |
| `-d, --deploy` | Deploy uploaded revision to `--env` (requires `--env`) |
| `-D, --download` | Download latest revision from Apigee to local folder |
| `--deployed` | Use with `-D` to download the currently deployed revision |
| `-r, --revision N` | Use with `-D` to download a specific revision number |
| `-e, --env <env>` | Target environment: `dev`, `test`, `sand`, `stage`, `prod` |
| `-o, --org <org>` | Override the org derived from `--env` |
| `-k, --sa-key <f>` | Override the SA key file derived from `--env` |
| `-t, --token <tok>` | Bearer token (overrides all auth methods) |
| `-a, --all` | Process all bundles found in current directory |
| `-v, --verbose` | Print full API responses |
| `-y, --yes` | Skip confirmation prompt (non-interactive) |

### Examples

```bash
# Zip only (no upload)
apigee-push ais-openai-direct-v2

# Zip all bundles in current directory
apigee-push -a

# Upload one bundle to dev (zip + upload, no deploy)
apigee-push -e dev ais-openai-direct-v2

# Upload and deploy one bundle to dev
apigee-push -e dev -d ais-openai-direct-v2

# Upload and deploy all bundles to stage
apigee-push -e stage -d -a

# Upload and deploy to prod (non-interactive)
apigee-push -e prod -d --yes adex-ais-cors ais-openai-direct-v2

# Download the latest revision of a proxy from dev
apigee-push -D -e dev ais-openai-direct-v2

# Download the currently deployed revision
apigee-push -D -e stage --deployed ais-openai-direct-v2
```

---

## Bundle detection

`apigee-push` determines bundle type by folder structure:

- Folder contains `proxies/` → `apiproxy`
- Folder contains `sharedflows/` → `sharedflowbundle`

The canonical bundle name is read from the root XML descriptor (`APIProxy` or `SharedFlowBundle` `name` attribute), not the folder name.

`.git` directories are always excluded from the zip.

---

## Claude Code skill

If you use [Claude Code](https://claude.ai/code), you can add an `/apigee` slash command that wraps this tool with context awareness — auto-detecting changed bundles, enforcing shared-flow-before-proxy deploy order, and accepting natural language arguments.

See [`claude/apigee.md`](claude/apigee.md) for the skill definition.

---

## License

MIT
