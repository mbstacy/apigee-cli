# apigee-cli

CLI tool for managing Apigee X proxy and shared flow bundles. Packages folders into zips, uploads to Apigee, deploys revisions, downloads from Apigee, compares local vs remote, lists what's deployed, and reads key value maps (KVMs).

---

## Features

- Zips, uploads, and deploys in one step
- Auto-detects bundle type and name from XML descriptor
- Supports proxies and shared flows
- Per-environment org and SA key config via `~/.apigee-cli`
- `--all` flag to process every bundle in the current directory
- `--list` to show all proxies/shared flows deployed in an environment
- `--check-version` to compare local files against Apigee revisions
- `--download` to pull a revision from Apigee back to local
- `--kvm` to list KVMs and read their entries (environment, proxy, or org scope), with optional masking
- `--yes` for non-interactive use (CI, scripting, Claude Code skill)
- Git branch safety check before deploy

---

## Prerequisites

- `bash` 4+
- [`gcloud`](https://cloud.google.com/sdk/docs/install) (for authentication)
- `curl`
- `jq`
- `zip` / `unzip`
- Service account key files for your Apigee orgs

---

## Installation

Run the install script from the repo root:

```bash
./install.sh
```

This will:
1. Copy `apigee-cli` to `~/local/bin/` and make it executable
2. Install the Claude Code `/apigee-cli` slash command to `~/.claude/commands/`
3. Interactively prompt for your Apigee org names and SA key file paths, then create `~/.apigee-cli`

Make sure `~/local/bin` is on your PATH:

```bash
# Add to your ~/.bashrc or ~/.zshrc if not already there
export PATH="$HOME/local/bin:$PATH"
```

**Or install manually:**

```bash
# Copy the script
cp apigee-cli ~/local/bin/apigee-cli
chmod +x ~/local/bin/apigee-cli

# Copy the Claude Code skill (optional)
cp claude/apigee-cli.md ~/.claude/commands/apigee-cli.md

# Create the config
cp ~/.apigee-cli.example ~/.apigee-cli   # then edit with your values
```

---

## Configuration

Create `~/.apigee-cli` with your org names and service account key paths:

```bash
DEV_ORG=my-nonprod-org
DEV_SA_KEY=/path/to/your/nonprod-sa-key.json

TEST_ORG=my-nonprod-org
TEST_SA_KEY=/path/to/your/nonprod-sa-key.json

SAND_ORG=my-nonprod-org
SAND_SA_KEY=/path/to/your/nonprod-sa-key.json

STAGE_ORG=my-preprod-org
STAGE_SA_KEY=/path/to/your/preprod-sa-key.json

PROD_ORG=my-prod-org
PROD_SA_KEY=/path/to/your/prod-sa-key.json
```

Each environment maps to its own org and SA key. The `--env` flag selects which pair to use. You can override per-run with `-o/--org` or `-k/--sa-key`.

If no SA key is configured, `apigee-cli` falls back to your active `gcloud` session (`gcloud auth print-access-token`).

Falls back to `~/.apigee-push` if `~/.apigee-cli` doesn't exist (backwards compatibility).

---

## Usage

```
apigee-cli [OPTIONS] [FOLDER_NAME ...]
```

### Options

| Flag | Description |
|------|-------------|
| `-u`, `--upload` | Upload bundles to Apigee after zipping |
| `-d`, `--deploy` | Deploy uploaded revision to `--env` after upload |
| `-D`, `--download` | Download revision from Apigee into local folder |
| `--deployed` | Use with `-D` to get the currently deployed revision |
| `-r`, `--revision N` | Use with `-D` to download a specific revision |
| `-L`, `--list` | List all proxies and/or shared flows in an environment |
| `-C`, `--check-version` | Compare local files against latest + deployed revisions in Apigee |
| `-K`, `--kvm [NAME]` | Read a KVM's entries. Omit `NAME` to list the KVMs in the scope. |
| `--proxy <name>` | Use with `-K` for a proxy-scoped KVM |
| `--org-scope` | Use with `-K` for an org-scoped KVM (default: the `--env` environment) |
| `--entry <name>` | Use with `-K` to read a single entry |
| `--mask` | Use with `-K` to mask values (first 7 and last 4 characters) |
| `-e`, `--env <env>` | Target environment: `dev`, `test`, `sand`, `stage`, `prod` |
| `-o`, `--org <org>` | Override the org derived from `--env` |
| `-k`, `--sa-key <file>` | Override the SA key file derived from `--env` |
| `-t`, `--token <tok>` | Bearer token (overrides all auth methods) |
| `-a`, `--all` | Process all bundles found in current directory |
| `-v`, `--verbose` | Print full API responses (with `-K`, print the entries as JSON) |
| `-y`, `--yes` | Skip confirmation prompts |

### Examples

```bash
# Deploy
apigee-cli -e dev -d ais-openai-direct-v2          # deploy one bundle to dev
apigee-cli -e prod -d -a                           # deploy all bundles to prod

# Upload only (no deploy)
apigee-cli -e dev ais-bedrock-llm                  # upload one bundle
apigee-cli -e dev -a                               # upload all bundles

# List
apigee-cli -e dev -L                               # list all proxies + shared flows in dev
apigee-cli -e dev -L proxies                       # list only proxies
apigee-cli -e dev -L sharedflows                   # list only shared flows

# Check local vs remote
apigee-cli -e dev -C ais-openai-direct-v2          # check one bundle vs dev
apigee-cli -e stage -C -a                          # check all bundles vs stage

# Download
apigee-cli -e dev -D ais-openai-direct-v2          # download latest revision
apigee-cli -e dev -D --deployed ais-openai-direct-v2  # download deployed revision
apigee-cli -e dev -D -r 5 ais-openai-direct-v2    # download specific revision

# Read KVMs (read-only)
apigee-cli -e dev -K                               # list env-scoped KVMs in dev
apigee-cli -e dev -K adex-splunk-kvm               # read every entry of an env KVM
apigee-cli -e prod -K --proxy my-proxy             # list a proxy's KVMs
apigee-cli -e prod -K my-proxy-kvm --proxy my-proxy --mask         # masked values
apigee-cli -e prod -K my-proxy-kvm --proxy my-proxy --entry api-key  # one entry
apigee-cli -e dev -K --org-scope                   # list org-scoped KVMs

# Zip only (no upload)
apigee-cli -a                                      # zip all bundles
apigee-cli ais-bedrock-llm                         # zip one bundle
```

### Reading KVMs

`-K` is read-only, so it never asks for confirmation. It uses the org and credentials for `--env` from `~/.apigee-cli`, like every other mode. That identity needs permission to read KVM entries.

Values are printed in full unless you pass `--mask`. KVMs often hold secrets, so use `--mask` when the output may be logged or shared.

### Environment-to-branch mapping

When deploying, `apigee-cli` checks your git branch against the expected branch for the target environment:

| Environment | Expected branch |
|-------------|----------------|
| dev, test, sand | `development` |
| stage | `stage` |
| prod | `main` |

A warning is shown if the branch doesn't match — you can still proceed.

---

## Bundle detection

`apigee-cli` determines bundle type by folder structure:

- Folder contains `proxies/` → `apiproxy`
- Folder contains `sharedflows/` → `sharedflowbundle`

The canonical bundle name is read from the root XML descriptor (`APIProxy` or `SharedFlowBundle` `name` attribute), not the folder name.

`.git` directories and `.md` files are always excluded from the zip.

---

## Claude Code integration

The `/apigee-cli` slash command provides a natural-language interface to `apigee-cli` within Claude Code. It parses arguments like `dev openai` or `stage -C` and runs the appropriate command.

The skill file is installed to `~/.claude/commands/apigee-cli.md` by the install script.

### Slash command examples

```
/apigee-cli dev deploy openai        # deploy ais-openai-direct-v2 to dev
/apigee-cli stage -C                 # check all bundles against stage
/apigee-cli dev -L proxies           # list proxies in dev
/apigee-cli prod kvm my-proxy-kvm --proxy my-proxy --mask   # read a proxy KVM, masked
```

See [`claude/apigee-cli.md`](claude/apigee-cli.md) for the skill definition.

---

## License

MIT
