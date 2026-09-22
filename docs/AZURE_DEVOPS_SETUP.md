# Azure DevOps and service connection setup

This guide connects this Bicep practice repository to Azure DevOps without storing Azure credentials in source control. It uses an Azure Resource Manager service connection with workload identity federation.

## Before you start

- An Azure DevOps organization and project.
- An Azure subscription where you may create the practice resource group.
- Permission to create service connections in the Azure DevOps project.
- `Owner` on the Azure subscription for the automatic service-connection path, or an existing Microsoft Entra app registration/managed identity for the manual path.

The deployment pipeline uses `eastus` and creates resources in `rg-bicep-practice` unless you change its variables.

## 1. Push the repository to Azure Repos

1. In Azure DevOps, select **New project** or open an existing project.
2. Open **Repos** → **Files** → **New repository** and create a Git repository.
3. Push this practice repository to the new repository's `main` branch.
4. Confirm these files are present:

   - `main.bicep`
   - `parameters/main.bicepparam`
   - `azure-pipelines.yml`

## 2. Register Azure resource providers

Run these once against the target subscription. Registration can take several minutes.

```bash
az login
az account set --subscription '<subscription-id-or-name>'

az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.DBforPostgreSQL
```

Check registration when needed:

```bash
az provider show --namespace Microsoft.App --query registrationState --output tsv
```

## 3. Create the Azure Resource Manager service connection

In Azure DevOps, open **Project settings** → **Service connections** → **New service connection** → **Azure Resource Manager**.

### Recommended: automatic workload identity federation

Choose **App registration (automatic)** and **Workload identity federation** when you have `Owner` on the subscription.

1. Select the target Azure subscription.
2. Name the connection `Azure-Service-Connection`.
3. Save it.
4. Authorize only this pipeline to use the connection when Azure DevOps prompts you. Avoid granting all pipelines access unless that is intentional.

Azure DevOps creates the app registration and federated credential. It uses federation rather than a client secret, so there is no secret to rotate or store in Azure DevOps.

### Manual workload identity federation

Use this path if automatic setup is unavailable.

1. Create or identify a Microsoft Entra app registration or user-assigned managed identity.
2. Grant it the least privilege needed. For this learning pipeline, `Contributor` at subscription scope permits it to create `rg-bicep-practice`; in a shared subscription, scope access as narrowly as your resource-group creation workflow allows.
3. In the service connection wizard, choose **Service principal (manual)**, then select **App registration or managed identity (manual)** and **Workload identity federation**.
4. Complete the subscription, tenant, and identity details. Follow the wizard to create the federated credential, verify, and save the connection.

## 4. Create the pipeline

1. Open **Pipelines** → **New pipeline**.
2. Select **Azure Repos Git**, then select this repository.
3. Select **Existing Azure Pipelines YAML file** and choose `/azure-pipelines.yml`.
4. Review and run the pipeline.
5. When prompted, authorize the pipeline to use `Azure-Service-Connection`.

## 5. Configure pipeline variables

Edit the `variables` section in `azure-pipelines.yml`, or create a variable group with equivalent values.

| Variable | Example value | Notes |
| --- | --- | --- |
| `azureServiceConnection` | `Azure-Service-Connection` | Must exactly match the service connection name. |
| `resourceGroupName` | `rg-bicep-practice` | The pipeline creates it if it does not exist. |
| `location` | `eastus` | Target Azure region. |

The parameter file controls optional resources. Keep the Container Registry, Container App, PostgreSQL, and Log Analytics options disabled until you are ready to practise them and accept their costs.

## 6. Add deployment approval

1. Open **Pipelines** → **Environments**.
2. Create an environment named `practice`.
3. Open **Approvals and checks** for that environment.
4. Add an approval check and choose the approvers.

The deployment job already targets `environment: practice`. The pipeline starts only when manually run from Azure DevOps. A run from `main` deploys after the environment approval succeeds.

## 7. First run

1. Open **Pipelines** → your pipeline → **Run pipeline**, select `main`, and start it.
2. Confirm the **Validate** stage passes.
3. Review the What-If output in the **Deploy** stage.
4. Approve the `practice` environment deployment when prompted.
5. Review deployment outputs in the Azure portal or with:

   ```bash
   az deployment group show \
     --resource-group rg-bicep-practice \
     --name '<deployment-name>' \
     --query properties.outputs
   ```

## PostgreSQL secret

PostgreSQL is disabled by default, and the supplied pipeline intentionally has no database-password variable. To enable it in a pipeline, first create a secret variable named `postgresAdminPassword`, map it to `POSTGRES_ADMIN_PASSWORD` in the Azure CLI task environment, and update the deployment task to create a temporary JSON parameter file. Bicep parameter files cannot be combined with inline parameter overrides, so use `main.bicep` directly for this optional path:

```bash
PARAMETER_FILE="$(Agent.TempDirectory)/postgres.parameters.json"
jq -n --arg password "$POSTGRES_ADMIN_PASSWORD" '{
  parameters: {
    namePrefix: { value: "iacpractice" },
    deployPostgres: { value: true },
    postgresAdminPassword: { value: $password }
  }
}' > "$PARAMETER_FILE"

az deployment group create \
  --name "practice-$(Build.BuildId)" \
  --resource-group "$(resourceGroupName)" \
  --template-file main.bicep \
  --parameters "@$PARAMETER_FILE"
```

Never add the password to `azure-pipelines.yml`, `main.bicepparam`, pipeline logs, or Git history.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Service connection cannot be saved | Confirm Azure DevOps service-connection permissions and the Azure identity/subscription permissions. |
| `AuthorizationFailed` | Confirm the connection identity has the required RBAC role at the target scope. |
| Resource provider error | Wait for the provider registration from step 2 to complete. |
| Deployment waits indefinitely | Check the `practice` environment approval/check configuration. |
| Container Apps deployment fails | Confirm `Microsoft.App` is registered and that the selected region supports Container Apps. |

## Official references

- [Create an Azure Resource Manager service connection with workload identity federation](https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure?view=azure-devops)
- [Manually configure workload identity federation](https://learn.microsoft.com/azure/devops/pipelines/release/configure-workload-identity?view=azure-devops)
- [Create and target Azure Pipelines environments](https://learn.microsoft.com/azure/devops/pipelines/process/environments?view=azure-devops)
