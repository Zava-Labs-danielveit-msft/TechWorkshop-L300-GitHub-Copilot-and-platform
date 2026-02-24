# GitHub Actions quickstart

This workflow builds the container image from ./src, pushes it to ACR, and deploys it to the App Service.

## Required GitHub secrets

Create this repository secret:

- AZURE_CREDENTIALS

Use a Microsoft Entra app registration and store the JSON output of `az ad sp create-for-rbac --json-auth` in this secret. Ensure the app has Contributor on the resource group.

If you run the command from Git Bash on Windows, prefix the scope with `//` to avoid path rewriting:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
	--role Contributor \
	--scopes "//subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/<YOUR_RESOURCE_GROUP>" \
	--json-auth
```

If you run it from PowerShell, use the normal scope path:

```powershell
az ad sp create-for-rbac --name "github-actions-sp" `
	--role Contributor `
	--scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/<YOUR_RESOURCE_GROUP>" `
	--json-auth
```

## Required GitHub variables

Create these repository variables:

- AZURE_CONTAINER_REGISTRY_NAME (example: zavaacrfskgi7ktnhul2)
- AZURE_APP_SERVICE_NAME (example: zava-web-dev-fskgi7ktnhul2)

The image name is set to `zavastorefront` in the workflow env. Change it there if needed.

## Run

Trigger the workflow manually or by pushing to the `main` or `dev` branch to deploy.
