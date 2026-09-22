# Azure Bicep practice repository

A small, safe-by-default Azure Infrastructure as Code (IaC) lab. It uses a root Bicep file to compose reusable resource modules, then validates and deploys them through Azure DevOps Pipelines.

## What it deploys

| Module | Azure resource | Learning focus |
| --- | --- | --- |
| `modules/network.bicep` | Virtual network and application subnet | address spaces and subnets |
| `modules/storage-account.bicep` | Standard LRS StorageV2 account | global names and secure storage defaults |
| `modules/key-vault.bicep` | Key Vault with Azure RBAC | secrets architecture without secret values in code |
| `modules/log-analytics.bicep` | Optional Log Analytics workspace | conditional module deployment |
| `modules/container-registry.bicep` | Azure Container Registry (Basic) | registry naming and disabled admin credentials |
| `modules/container-app-environment.bicep` | Container Apps managed environment | container hosting foundation |
| `modules/container-app.bicep` | Container App | managed identity, ingress, and scale-to-zero |
| `modules/postgresql-flexible-server.bicep` | PostgreSQL Flexible Server and database | secure deployment-time parameters and database resources |

`main.bicep` is the entry point. It passes common location, name-prefix, and tag values to each module and exposes useful outputs.

## Prerequisites

- An Azure subscription where you can create a resource group and the resources above.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep support (`az bicep version`).
- An Azure DevOps project and an Azure Resource Manager service connection for the pipeline path.

If this subscription has not used these services before, register their resource providers once (registration can take a few minutes):

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.DBforPostgreSQL
```

## Deploy from your machine

Sign in and select the right subscription:

```bash
az login
az account set --subscription '<subscription-id-or-name>'
```

Edit `parameters/main.bicepparam` and give `namePrefix` a short, distinctive value using only letters and numbers. Then create a resource group and preview the change:

```bash
az group create --name rg-bicep-practice --location australiaeast
az deployment group what-if \
  --name practice-preview \
  --resource-group rg-bicep-practice \
  --parameters parameters/main.bicepparam
```

Deploy after reviewing the preview:

```bash
az deployment group create \
  --name practice-deployment \
  --resource-group rg-bicep-practice \
  --parameters parameters/main.bicepparam
```

## Optional container and database resources

The registry, Container App, and PostgreSQL resources are disabled in `parameters/main.bicepparam` to limit accidental cost. Set their corresponding `deploy...` parameter to `true` before previewing and deploying them.

The Container App starts from a public Microsoft sample image; the registry module is deliberately separate. A follow-up exercise is to assign the app identity `AcrPull` on the registry, point `containerImage` at your pushed image, and configure the registry reference without using admin credentials.

PostgreSQL requires a password, which must never be added to `main.bicepparam` or committed. Set it in your shell and pass it only when enabling PostgreSQL:

```bash
read -s POSTGRES_ADMIN_PASSWORD
export POSTGRES_ADMIN_PASSWORD
az deployment group create \
  --name practice-postgres \
  --resource-group rg-bicep-practice \
  --parameters parameters/main.bicepparam \
  deployPostgres=true \
  postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD"
```

For Azure Pipelines, store that value as a secret variable and pass it to the deployment command as `postgresAdminPassword`; do not log it. The initial database server exposes a public endpoint but defines no firewall rules, so it is not reachable until you intentionally add an access rule. A private-network PostgreSQL design requires a delegated subnet and private DNS zone, which is a useful next exercise.

Build locally (this also runs the configured Bicep linter):

```bash
az bicep build --file main.bicep --outdir ./dist
```

`dist/` is disposable; remove it when finished. It is not committed.

## Azure Pipelines

The pipeline in `azure-pipelines.yml` has two stages:

1. **Validate** runs `az bicep build`, including linter checks, for pull requests and pushes to `main`.
2. **Deploy** runs only for `main`: it creates the practice resource group if needed, runs What-If, then deploys.

Before running it, update the three pipeline variables (or replace them with a variable group):

- `azureServiceConnection`: the name of your Azure Resource Manager service connection.
- `resourceGroupName`: the resource group for this lab.
- `location`: the resource group location.

Use Azure DevOps environment approvals on the `practice` environment before enabling automatic deployment in a shared subscription. The service connection must be authorized to create the resource group and deploy resources within it.

### Azure DevOps setup

1. Create a project in [Azure DevOps](https://dev.azure.com), then create an empty Git repository. Push this folder to its `main` branch.
2. Choose the service-connection approach. If you have `Owner` on the learning subscription, use **App registration (automatic)** with **Workload identity federation**. Otherwise, use an existing app registration or managed identity with workload identity federation and give that identity `Contributor` at the narrowest scope that can create the practice resource group and its resources.
3. In Azure DevOps, open **Project settings** → **Service connections** → **New service connection** → **Azure Resource Manager**. Choose the approach from step 2, select the subscription, give it a name such as `Azure-Service-Connection`, and authorize this pipeline to use it.
4. Open **Pipelines** → **New pipeline**, choose **Azure Repos Git**, select this repository, then choose **Existing Azure Pipelines YAML file** and select `/azure-pipelines.yml`.
5. Before the first run, edit the `variables` section in `azure-pipelines.yml`, or map these values from a variable group:

   | Variable | Example | Purpose |
   | --- | --- | --- |
   | `azureServiceConnection` | `Azure-Service-Connection` | ARM service connection name from step 3 |
   | `resourceGroupName` | `rg-bicep-practice` | Resource group created or reused by deployment |
   | `location` | `australiaeast` | Azure region for the resource group |

6. Open **Pipelines** → **Environments**, create an environment named `practice`, then add an approval check if deployments need human confirmation. The YAML already targets this environment.
7. Create a pull request to `main`. The **Validate** stage compiles and lints the Bicep templates. Merge it only after validation succeeds.
8. A push to `main` runs the deployment stage: it creates the resource group when needed, runs What-If, waits for the `practice` environment approval if configured, and deploys.

To enable the optional PostgreSQL module in a pipeline, add `postgresAdminPassword` as a secret variable or secret variable-group entry. Pass it into the final `az deployment group create` command as `postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD"`; never add it to `azure-pipelines.yml` or `parameters/main.bicepparam`.

## Exercises

1. Change the storage SKU to `Standard_ZRS` and confirm the What-If output.
2. Add a second subnet module parameter and a network security group.
3. Set `deployLogAnalytics` to `true`, deploy, and inspect the workspace.
4. Add a private endpoint for the storage account, then change its networking design deliberately.
5. Add diagnostic settings that send a resource's logs to the workspace.
6. Push an image to the registry and let the Container App pull it through managed identity and the `AcrPull` role.
7. Add PostgreSQL private networking with a delegated subnet and private DNS zone.

## Security and cost notes

- No credentials, secrets, or subscription IDs are committed. Key Vault uses Azure RBAC and has no access policies defined in the template.
- Storage public access and shared-key access are disabled. Key Vault denies data-plane access by default; add narrowly scoped network rules or private endpoints as a later exercise.
- The Log Analytics workspace is optional because ingestion can incur cost. Review Azure pricing and your subscription policy before enabling it.

## Clean up

Delete the lab resource group when you are done. This removes the deployed resources:

```bash
az group delete --name rg-bicep-practice --yes --no-wait
```

Key Vault soft-delete retention is seven days. Purge protection is intentionally off in this learning repository so the lab is easier to remove; do not copy that setting to production without considering recovery requirements.

## Reference documentation

- [Bicep modules](https://learn.microsoft.com/azure/azure-resource-manager/bicep/modules)
- [Deploy Bicep with Azure CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-cli)
- [Bicep What-If](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if)
- [AzureCLI@2 task](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/azure-cli-v2?view=azure-pipelines)
- [Container Registry resource reference](https://learn.microsoft.com/azure/templates/microsoft.containerregistry/2025-04-01/registries)
- [Container Apps resource reference](https://learn.microsoft.com/azure/templates/microsoft.app/2025-01-01/containerapps)
- [PostgreSQL Flexible Server resource reference](https://learn.microsoft.com/azure/templates/microsoft.dbforpostgresql/2025-08-01/flexibleservers)
