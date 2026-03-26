Bundle, upload, and deploy Apigee proxy/shared flow bundles using the following arguments: $ARGUMENTS

The apigee-push script is installed on PATH. Always run it from the working directory containing the Apigee bundle folders.

## Argument parsing

Parse $ARGUMENTS as: [env] [bundle names...]

- env: one of dev, test, sand, stage, prod (required for upload/deploy)
- bundle names: one or more folder names to deploy (optional — if omitted, detect from git changes)

Examples:
- "dev ais-openai-direct-v2" → deploy one bundle to dev
- "stage" → detect changed bundles, deploy all to stage
- "prod adex-ais-cors ais-openai-direct-v2" → deploy two bundles to prod

## Steps

1. Identify which bundles to deploy:
   - If bundle names were provided, use those exactly
   - If no bundle names were given, run `git diff --name-only HEAD` (or compare working tree) from the current directory to find which bundle folders have changes. A bundle folder contains a `proxies/` or `sharedflows/` subdirectory.

2. Order the bundles: shared flows must deploy before proxies that reference them.
   - Shared flows are folders with a `sharedflows/` subdirectory (e.g. adex-ais-cors, adex-ais-auth, adex-ais-preflow, adex-ais-fault, adex-ais-quota)
   - Proxies are folders with a `proxies/` subdirectory (e.g. ais-openai-direct-v2, ais-google-gemini-v2, ais-bedrock-llm)
   - Always deploy shared flows first, then proxies

3. Show the user what will be deployed (bundles in order, target env) and ask for confirmation before running.

4. Run apigee-push with --yes (non-interactive) once confirmed:
   ```
   apigee-push -e <env> -d --yes <bundle1> <bundle2> ...
   ```

5. Report the result — revision numbers deployed and any errors.

## Notes
- If env is prod, call out that this is a production deployment and confirm explicitly before proceeding
- If a bundle folder doesn't exist locally, skip it with a warning
- The script handles authentication via ~/.apigee-push config automatically
