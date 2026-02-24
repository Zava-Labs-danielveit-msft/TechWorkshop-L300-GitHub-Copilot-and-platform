# ZavaStorefront Infrastructure (AZD + Bicep)

This folder defines the Azure infrastructure for the ZavaStorefront dev environment.

## What gets created

- Resource group (selected by azd)
- Azure Container Registry (ACR)
- Linux App Service Plan + Web App for Containers
- Log Analytics workspace + Application Insights
- Azure AI Foundry (Azure AI Services) account with GPT-4 and Phi deployments
- AcrPull role assignment for the Web App managed identity

## Notes

- All resources default to westus3. Update parameters in [infra/main.parameters.json](infra/main.parameters.json) if needed.
- The Web App pulls the container image from ACR using managed identity (no passwords).
- Model names, versions, and capacities are defaults. If a model is not available in westus3, set the deployment flags to false and provision, then re-enable with supported models.

## Typical workflow

1. Initialize AZD at the repo root:

   ```bash
   azd init
   ```

2. Preview infrastructure changes:

   ```bash
   azd provision --preview
   ```

3. Provision infrastructure:

   ```bash
   azd provision
   ```

4. Build and push container image without local Docker (cloud build):

   ```bash
   az acr build --registry <acr-name> --image zavastorefront:dev ./src
   ```

5. Deploy the app to the Web App:

   ```bash
   azd deploy
   ```

## Required inputs

- Azure subscription with access to Azure AI Foundry in westus3
- Available model deployments for GPT-4 and Phi in the selected region
