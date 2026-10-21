Bundle, upload, and deploy Apigee proxy/shared flow bundles, or read Apigee KVMs, using the following arguments: $ARGUMENTS

The apigee-cli script is installed on PATH. Always run it from the working directory containing the Apigee bundle folders. KVM mode (`-K`) doesn't need bundle folders and can run from any directory.

## apigee-cli flags (pass these through directly — do not reinterpret)

| Flag | Meaning |
|------|---------|
| `-C` / `--check-version` | Compare local files against latest + deployed revisions in Apigee |
| `-d` / `--deploy` | Deploy after upload |
| `-D` / `--download` | Download revision from Apigee to local |
| `--deployed` | Use with `-D` to get the currently deployed revision |
| `-r N` / `--revision N` | Use with `-D` to download a specific revision |
| `-a` / `--all` | Process all bundles in current directory |
| `-L` / `--list` | List all proxies/shared flows in an environment (optional: `proxies` or `sharedflows` filter) |
| `-K [NAME]` / `--kvm [NAME]` | Read a KVM's entries (read-only). Omit NAME to list the KVMs in the scope. |
| `--proxy <name>` | Use with `-K` for a proxy-scoped KVM |
| `--org-scope` | Use with `-K` for an org-scoped KVM (default: env scope) |
| `--entry <name>` | Use with `-K` to read one entry |
| `--mask` | Use with `-K` to mask values |
| `-v` / `--verbose` | Print full API responses (with `-K`, entries as JSON) |

If $ARGUMENTS contains any of these flags, pass them straight to apigee-cli without reinterpreting. Always append `--yes` and `-e <env>`.

The word `kvm` in $ARGUMENTS means `-K`. The word after it, if any, is the KVM name.

## Argument parsing

Parse $ARGUMENTS as: [flags...] [env] [bundle names...]

- env: one of dev, test, sand, stage, prod
- bundle names: one or more folder names (optional — if omitted and no `-a`, detect from git changes)
- Partial names are allowed: "openai" → ais-openai-direct-v2, "cors" → adex-ais-cors, "auth" → adex-ais-auth, etc.

Examples:
- `dev openai` → deploy ais-openai-direct-v2 to dev
- `stage -C` → check all bundles against stage
- `stage -C openai` → check ais-openai-direct-v2 against stage
- `dev deploy openai` → deploy ais-openai-direct-v2 to dev
- `prod adex-ais-cors ais-openai-direct-v2` → deploy two bundles to prod
- `dev -L` → list all proxies and shared flows in dev
- `dev -L proxies` → list only proxies in dev
- `list dev` → list all in dev
- `dev kvm` → list env-scoped KVMs in dev
- `prod kvm my-proxy-kvm --proxy my-proxy` → read a proxy-scoped KVM in prod
- `prod kvm my-proxy-kvm --proxy my-proxy --entry api-key --mask` → read one entry, masked

## Steps

1. Identify the mode from flags:
   - `-C` → check-version mode (no deploy, no confirmation needed, just run)
   - `-d` or "deploy" in args → deploy mode
   - `-D` → download mode
   - `-L` or "list" in args → list mode (no bundles needed, just env; optional filter: `proxies` or `sharedflows`)
   - `-K` or `kvm` → KVM mode (read-only, no bundles, no confirmation needed, just run)
   - No flag → default to deploy mode

2. Identify which bundles:
   - If bundle names were provided (or partial names), resolve to full folder names
   - If `-a` was given, pass `-a` to apigee-cli
   - If no bundle names and no `-a`, run `git diff --name-only HEAD` to find changed bundle folders

3. Order the bundles (deploy mode only): shared flows first, then proxies.
   - Shared flows: folders with `sharedflows/` (adex-ais-cors, adex-ais-auth, adex-ais-preflow, adex-ais-fault, adex-ais-quota, ais-vector-store-kvm-*)
   - Proxies: folders with `proxies/` (ais-openai-direct-v2, ais-google-gemini-v2, ais-bedrock-llm)

4. For deploy mode: show what will be deployed and ask for confirmation. For prod, warn explicitly.

5. Run apigee-cli:
   - Check:  `apigee-cli -e <env> -C --yes <bundles...>`
   - Deploy: `apigee-cli -e <env> -d --yes <bundles...>`
   - All:    `apigee-cli -e <env> -C --yes -a` or `apigee-cli -e <env> -d --yes -a`
   - List:   `apigee-cli -e <env> -L --yes [proxies|sharedflows]`
   - KVM:    `apigee-cli -e <env> -K [<kvm>] [--proxy <proxy> | --org-scope] [--entry <name>] [--mask] --yes`

6. Report the result.

## Notes
- The script handles authentication via ~/.apigee-cli config automatically
- If a bundle folder doesn't exist locally, skip it with a warning
- KVM values are often secrets. Without `--mask`, the full values end up in the conversation, so pass `--mask` unless the user asked for the full values
