Bundle, upload, and deploy Apigee proxy/shared flow bundles using the following arguments: $ARGUMENTS

The apigee-push script is installed on PATH. Always run it from the working directory containing the Apigee bundle folders.

## apigee-push flags (pass these through directly — do not reinterpret)

| Flag | Meaning |
|------|---------|
| `-C` / `--check-version` | Compare local files against latest + deployed revisions in Apigee |
| `-d` / `--deploy` | Deploy after upload |
| `-D` / `--download` | Download revision from Apigee to local |
| `--deployed` | Use with `-D` to get the currently deployed revision |
| `-r N` / `--revision N` | Use with `-D` to download a specific revision |
| `-a` / `--all` | Process all bundles in current directory |
| `-v` / `--verbose` | Print full API responses |

If $ARGUMENTS contains any of these flags, pass them straight to apigee-push without reinterpreting. Always append `--yes` and `-e <env>`.

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

## Steps

1. Identify the mode from flags:
   - `-C` → check-version mode (no deploy, no confirmation needed, just run)
   - `-d` or "deploy" in args → deploy mode
   - `-D` → download mode
   - No flag → default to deploy mode

2. Identify which bundles:
   - If bundle names were provided (or partial names), resolve to full folder names
   - If `-a` was given, pass `-a` to apigee-push
   - If no bundle names and no `-a`, run `git diff --name-only HEAD` to find changed bundle folders

3. Order the bundles (deploy mode only): shared flows first, then proxies.
   - Shared flows: folders with `sharedflows/` (adex-ais-cors, adex-ais-auth, adex-ais-preflow, adex-ais-fault, adex-ais-quota, ais-vector-store-kvm-*)
   - Proxies: folders with `proxies/` (ais-openai-direct-v2, ais-google-gemini-v2, ais-bedrock-llm)

4. For deploy mode: show what will be deployed and ask for confirmation. For prod, warn explicitly.

5. Run apigee-push:
   - Check:  `apigee-push -e <env> -C --yes <bundles...>`
   - Deploy: `apigee-push -e <env> -d --yes <bundles...>`
   - All:    `apigee-push -e <env> -C --yes -a` or `apigee-push -e <env> -d --yes -a`

6. Report the result.

## Notes
- The script handles authentication via ~/.apigee-push config automatically
- If a bundle folder doesn't exist locally, skip it with a warning
