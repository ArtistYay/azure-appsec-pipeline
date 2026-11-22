# Azure Appsec Pipeline
Intersecting DevSecOps to security operations

## Why This Exists

Most companies have a CI/CD pipeline and a SIEM, but the two don't talk to each other. The pipeline knows what got deployed and whether it passed a scan. The SIEM knows something went wrong at runtime. Neither one has the other's context, and that gap is where real incidents slip through. A vulnerable image gets deployed, it starts misbehaving in production, and the security team investigating it has no idea what pipeline shipped it, whether it was scanned, or what changed right before things went sideways.

This project closes that gap. Every image is scanned before it can reach the registry and is tagged with the exact commit that produced it. The app writes structured JSON logs the moment something happens, Container Apps ships them to Log Analytics, and Microsoft Sentinel runs detection rules on top. So when Sentinel flags something, the running image traces straight back to one commit and one pipeline run.

The Terraform layer does the same thing for infrastructure. Instead of every developer hand-rolling their own network rules, encryption settings, and identity permissions, they call a module that already has secure defaults built in. Azure Policy sits on top as the enforcement layer, even if someone edits a module and strips out a control, the deployment gets blocked before it ever reaches production.

**What this means for a business:** the cost of a security incident isn't just the incident itself, it's the time spent figuring out how it happened. A pipeline that ties deployment context to runtime detection turns "something's wrong, we don't know what" into "here's exactly what shipped, when, and what it looked like passing every gate along the way." That's the difference between an incident response that takes hours and one that takes days.

I built this to prove I understand how these pieces actually fit together, not just that I know which button turns on Defender for Cloud. Anyone can enable a managed service. Fewer people can architect the pipeline that feeds it.

## Architecture

```
 Developer pushes to GitHub
          │
          ├─ terraform/** changed ──► terraform.yml
          │                             fmt → validate → tflint → Checkov
          │                             plan (every PR and push)
          │                             apply (main only, after reviewer approval)
          │                                 │
          │                                 ▼
          │                Azure: ACR, managed identity (AcrPull only), Container App,
          │                Log Analytics + Sentinel, Azure Policy, VNet/NSG
          │
          └─ app/** changed ──────► app-deploy.yml
                                        pytest → Bandit → Gitleaks
                                        docker build → Grype scan
                                        push to ACR (main only, tagged with commit SHA)
                                        deploy (main only, after reviewer approval) → smoke test
                                            │
                                            ▼
                     Container App → JSON logs → Log Analytics → Sentinel rule → incident
                                                                └→ Azure Monitor alert → Logic App → Discord
```

## Security controls, layer by layer

| Layer | Control | Where |
|---|---|---|
| Code | Unit tests, Bandit (Python SAST) | `app-deploy.yml` |
| Secrets | Gitleaks across full git history, plus GitHub secret scanning | `app-deploy.yml` |
| Dependencies | Dependabot for pip, Docker, Terraform and GitHub Actions | `.github/dependabot.yml` |
| Image | Grype fails the build on fixable HIGH/CRITICAL CVEs, before the image can reach ACR | `app-deploy.yml` |
| Image | Non-root user, Alpine base, no `latest` tags (every image is tagged with its commit SHA) | `Dockerfile`, `app-deploy.yml` |
| IaC | `terraform fmt`, `validate`, tflint, Checkov | `terraform.yml` |
| IaC | Variable validation blocks (region, SKU per environment, CPU/memory ratio, AcrPull only) | `terraform/**/variables.tf` |
| Cloud | Azure Policy denies wrong regions, wrong ACR SKUs, and bad CPU/memory ratios, even outside Terraform | `modules/policy` |
| Identity | App identity can only pull from one registry (AcrPull scoped to the ACR) | `modules/identity` |
| Identity | Pipeline has no stored secret, it authenticates with OIDC, trusted only for this repo's main branch, PRs and the `dev` environment | bootstrap below |
| Supply chain | Every GitHub Action is pinned to a full commit SHA, Dependabot keeps the pins current | both workflows |
| Change control | `terraform apply` and app deploys pause until a required reviewer approves | GitHub `dev` environment |
| Detection | Sentinel rule for web recon (repeated 404/405 probes from one IP), mapped to MITRE Reconnaissance/Discovery | `modules/monitoring` |
| Response | The same query raises an Azure Monitor alert that posts to Discord | `modules/monitoring` |

## Built With
- Python, Flask, Gunicorn, pytest
- Docker
- Terraform (azurerm 4.79)
- GitHub Actions
- Azure Container Apps, Azure Container Registry, Log Analytics, Microsoft Sentinel, Azure Policy, Logic Apps
- Bandit, Gitleaks, Grype, Checkov, tflint, Dependabot

## Pipeline Order

This project runs as two separate GitHub Actions workflows, triggered independently on path-based filters rather than chained together automatically:

- `terraform.yml` triggers on changes to `terraform/**`
- `app-deploy.yml` triggers on changes to `app/**`, `tests/**`, the `Dockerfile` and the requirements files

They're independent because most changes to one shouldn't automatically trigger the other. But there's a real dependency underneath: the Container App, ACR, and the identity's role assignment all have to exist in Azure before `app-deploy.yml` can build, push, or deploy anything.

**On a fresh environment, run `terraform.yml` first.** `app-deploy.yml` will fail if the infrastructure it depends on hasn't been provisioned yet.

### Who owns what

Terraform creates the Container App with a public placeholder image (`mcr.microsoft.com/k8se/quickstart`, listening on port 80), because on the very first run ACR is empty. From then on, `app-deploy.yml` owns which image runs and switches ingress to the app's real port (5000). Terraform's `lifecycle { ignore_changes }` on the image and target port stops every `terraform apply` from rolling the app back to the placeholder.

## Estimated Monthly Cost

This project is sized for a homelab/portfolio budget, not production traffic.

| Resource | Config | Est. Monthly Cost | Pricing Reference |
|---|---|---|---|
| Azure Container Registry | Basic tier | ~$5/month flat fee | [ACR Pricing](https://azure.microsoft.com/en-us/pricing/details/container-registry/) |
| Azure Container Apps | 0.5 vCPU / 1GiB, scales to zero | ~$0 when idle, fractions of a cent per request | [Container Apps Pricing](https://azure.microsoft.com/en-us/pricing/details/container-apps/) |
| Log Analytics Workspace | PerGB2018, 30-day retention | Under $1/month at this log volume | [Azure Monitor Pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/) |
| Microsoft Sentinel | On the same workspace | Free trial for the first 31 days, then cents per month at this volume | [Sentinel Pricing](https://azure.microsoft.com/en-us/pricing/details/microsoft-sentinel/) |
| Azure Monitor log alert | 1 rule, every 5 minutes | Roughly $0.50 to $1.50/month | [Azure Monitor Pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/) |
| Logic App (Consumption) | Runs only when an alert fires | Fractions of a cent per run | [Logic Apps Pricing](https://azure.microsoft.com/en-us/pricing/details/logic-apps/) |
| VNet, Subnet, NSG, Managed Identities, Azure Policy, Resource Group | N/A | $0 | N/A |
| Terraform state (Storage Account, LRS) | A few KB | ~$0.01-0.05/month | [Blob Storage Pricing](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/) |

**Realistic total: roughly $7-9/month**, mostly the ACR Basic flat fee. Run `terraform destroy` between sessions to drop it to almost $0. Destroy never touches the manually bootstrapped resource group, pipeline identity, or state storage.

## Prerequisites: One-Time Manual Setup

This project uses a `data` source (not a `resource`) for the resource group. That's a deliberate choice: GitHub Actions authenticates to Azure using OIDC, and the identity behind that authentication has to live in a resource group that Terraform never destroys. Otherwise, tearing down infrastructure for testing would also delete the very credentials the pipeline needs to run.

Run these once, signed in with an account that can assign roles on the subscription (Owner, or User Access Administrator plus Contributor). Check you're on the right subscription first with `az account show`.

**0. Set variables and register resource providers**

The pipeline identity is scoped to one resource group, so it can't register resource providers (that's a subscription-level action). Terraform's provider has `resource_provider_registrations = "none"` for that reason, so they're registered here once.

```bash
GITHUB_REPO="ArtistYay/azure-appsec-pipeline"
RG="rg-appsec-dev"
LOCATION="eastus"
SUB_ID=$(az account show --query id -o tsv)

for ns in Microsoft.App Microsoft.ContainerRegistry Microsoft.ManagedIdentity Microsoft.Network \
          Microsoft.OperationalInsights Microsoft.OperationsManagement Microsoft.SecurityInsights \
          Microsoft.Logic Microsoft.Insights Microsoft.Storage; do
  az provider register --namespace "$ns"
done
```

**1. Resource group**

```bash
az group create --name "$RG" --location "$LOCATION"
RG_ID=$(az group show --name "$RG" --query id -o tsv)
```

**2. Storage for Terraform's remote state**

Azure Blob Storage locks the state file with a blob lease, so two runs can't corrupt it at the same time. Shared key access is turned off, so the only way in is Entra ID (RBAC), no storage keys.

```bash
az storage account create \
  --name satfstateappsec \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false

# container-rm goes through Azure Resource Manager, so it works even though shared keys are off
# and you don't have a blob data role yet
az storage container-rm create \
  --storage-account satfstateappsec \
  --resource-group "$RG" \
  --name tfstate

STATE_SCOPE="$(az storage account show --name satfstateappsec --resource-group "$RG" --query id -o tsv)/blobServices/default/containers/tfstate"
```

**3. Pipeline identity and its OIDC trust**

```bash
az identity create --name id-github-actions-appsec --resource-group "$RG"
PIPELINE_ID=$(az identity show --name id-github-actions-appsec --resource-group "$RG" --query principalId -o tsv)
```

Each GitHub Actions job presents a token whose `subject` says where it's running. Azure federated credentials match that subject as an exact string (no wildcards), so the pipeline needs one credential per context it runs in:

| Credential | Subject | Used by |
|---|---|---|
| `github-main` | `repo:<repo>:ref:refs/heads/main` | plan and image push on main |
| `github-pr` | `repo:<repo>:pull_request` | plan on pull requests |
| `github-env-dev` | `repo:<repo>:environment:dev` | the approval-gated apply and deploy jobs |

```bash
for pair in "github-main:ref:refs/heads/main" "github-pr:pull_request" "github-env-dev:environment:dev"; do
  az identity federated-credential create \
    --name "${pair%%:*}" \
    --identity-name id-github-actions-appsec \
    --resource-group "$RG" \
    --issuer https://token.actions.githubusercontent.com \
    --subject "repo:${GITHUB_REPO}:${pair#*:}" \
    --audiences api://AzureADTokenExchange
done
```

The subject is a trust condition, not an ownership claim. A fork with identical workflow code presents a different repo path, so Azure rejects it.

Before creating these, confirm the repo still uses the classic subject format with `gh api /repos/ArtistYay/azure-appsec-pipeline/actions/oidc/customization/sub`. Repos created or renamed after July 15, 2026 get an immutable format with numeric IDs (`repo:owner@123/repo@456:...`), and the subject strings above would need to match that instead.

**4. Pipeline permissions**

`Contributor` alone isn't enough, because it explicitly blocks writing role assignments and policies, and this Terraform creates both. Instead of jumping to `Owner`, each extra permission is the narrowest one that works:

```bash
# Create and manage resources inside this resource group only
az role assignment create --assignee-object-id "$PIPELINE_ID" --assignee-principal-type ServicePrincipal \
  --role "Contributor" --scope "$RG_ID"

# Create role assignments, but ONLY the AcrPull role and ONLY for service principals.
# Without the condition, this role could grant itself Owner.
az role assignment create --assignee-object-id "$PIPELINE_ID" --assignee-principal-type ServicePrincipal \
  --role "Role Based Access Control Administrator" --scope "$RG_ID" \
  --condition-version "2.0" \
  --condition "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d} AND @Request[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d} AND @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}))"

# Policy definitions always live at subscription scope, so this one can't be narrower
az role assignment create --assignee-object-id "$PIPELINE_ID" --assignee-principal-type ServicePrincipal \
  --role "Resource Policy Contributor" --scope "/subscriptions/$SUB_ID"

# Read/write the state file with Entra ID, scoped to the one blob container
az role assignment create --assignee-object-id "$PIPELINE_ID" --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" --scope "$STATE_SCOPE"
```

`7f951dda-4ed3-4680-a7ca-43fe172d538d` is the built-in AcrPull role ID. The condition follows Microsoft's [Constrain ACR management example](https://learn.microsoft.com/azure/role-based-access-control/delegate-role-assignments-examples#example-constrain-acr-management).

**5. GitHub settings**

- Settings → Environments → **New environment** → `dev` → add yourself under **Required reviewers**. The apply and deploy jobs pause here until you approve.
- Settings → Secrets and variables → Actions → add:
  - `AZURE_CLIENT_ID`: `az identity show --name id-github-actions-appsec --resource-group rg-appsec-dev --query clientId -o tsv`
  - `AZURE_TENANT_ID`: `az account show --query tenantId -o tsv`
  - `AZURE_SUBSCRIPTION_ID`: `az account show --query id -o tsv`
  - `DISCORD_WEBHOOK_URL` (optional): from Discord, Server Settings → Integrations → Webhooks. Leave it unset to skip building the Discord path.

None of the first three are passwords, they're identifiers. What actually protects the pipeline is the federated credential's subject check.

## Running Terraform locally

Create `terraform/backend-local.conf` (it's gitignored):

```hcl
use_cli              = true
use_azuread_auth     = true
tenant_id            = "<your-tenant-id>"
storage_account_name = "satfstateappsec"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
```

Your own account also needs `Storage Blob Data Contributor` on the state container (same command as step 4, with your user's object ID), because shared key access is off. Then:

```bash
cd terraform
terraform init -backend-config=backend-local.conf
terraform fmt -recursive
terraform validate
terraform plan -var-file=environments/dev/terraform.tfvars
```

Run `fmt` and `validate` before every push. The pipeline runs the same checks and fails on them.

Run the app tests locally from the repo root:

```bash
pip install -r requirements.txt -r requirements-dev.txt
python -m pytest -q
bandit -r app -ll
```

## Testing the detection

The Sentinel rule fires when one IP gets 10 or more 404/405 responses in 5 minutes, which is what directory brute forcing, vulnerability scanners and HTTP method tampering look like.

```bash
APP_URL=$(az containerapp show --name ca-appsec-dev --resource-group rg-appsec-dev --query properties.configuration.ingress.fqdn -o tsv)

for path in admin .env wp-login.php backup.zip config.php .git/config api/v1/users phpmyadmin server-status login; do
  curl -s -o /dev/null -w "%{http_code} /$path\n" "https://$APP_URL/$path"
done
curl -s -o /dev/null -w "%{http_code} POST /health\n" -X POST "https://$APP_URL/health"
```

Then check Sentinel → Incidents. Allow 5 to 15 minutes: logs take a few minutes to reach Log Analytics, and the rule runs every 5 minutes. The incident maps the attacking IP as an entity, and the alert shows the sampled paths.

## Proving least privilege

The app's identity should be able to do exactly one thing: pull images from this one registry.

**1. List every role it holds, across the whole subscription.** Expect exactly one row: `AcrPull`, scoped to the ACR.

```bash
APP_ID=$(az identity show --name id-appsec-dev --resource-group rg-appsec-dev --query principalId -o tsv)
az role assignment list --assignee "$APP_ID" --all -o table
```

**2. Try something it shouldn't be allowed to do, from inside the running container.** Container Apps gives the container a local token endpoint for its managed identity. The app scales to zero, so hit `/health` first to make sure a replica is running, then open a shell in it:

```bash
az containerapp exec --name ca-appsec-dev --resource-group rg-appsec-dev --command sh
```

Inside, ask for an Azure Resource Manager token as the app identity and try to list resource groups (replace the two placeholders):

```sh
python3 - <<'EOF'
import json, os, urllib.request, urllib.error
CLIENT_ID = "<client id of id-appsec-dev>"
SUB_ID = "<subscription id>"
token_url = (f"{os.environ['IDENTITY_ENDPOINT']}?resource=https://management.azure.com/"
             f"&api-version=2019-08-01&client_id={CLIENT_ID}")
token = json.load(urllib.request.urlopen(urllib.request.Request(
    token_url, headers={"X-IDENTITY-HEADER": os.environ["IDENTITY_HEADER"]})))["access_token"]
try:
    urllib.request.urlopen(urllib.request.Request(
        f"https://management.azure.com/subscriptions/{SUB_ID}/resourcegroups?api-version=2021-04-01",
        headers={"Authorization": f"Bearer {token}"}))
    print("UNEXPECTED: listing resource groups worked")
except urllib.error.HTTPError as e:
    print(e.code, json.load(e).get("error", {}).get("code"))
EOF
```

Expect `403 AuthorizationFailed`. The identity has a valid token, it just isn't allowed to do anything with it except pull from ACR. A failure here is the good result.

## Known gaps and tradeoffs

These are deliberate calls for a portfolio project, documented so they read as decisions, not oversights.

- **No VNet integration.** The network module works, but the Container Apps environment isn't deployed into it, so the app has a public endpoint. The fix is `infrastructure_subnet_id` on the environment with a delegated `/23` subnet, plus an internal-only environment behind Application Gateway if it needs to stay reachable.
- **ACR is Basic and public.** Private endpoints, content trust, quarantine and retention policies all need Premium (~$50/month). Each related Checkov check is skipped inline with its reason in `modules/storage/main.tf`. The `acr_sku` validation already forces Premium when `environment = "production"`.
- **Pipeline Contributor is broad within the resource group.** A custom role listing only the resource types this Terraform creates would be tighter. The other three pipeline roles are already narrowed (conditional RBAC admin, policy-only, one blob container).
- **PR plans use the same identity as apply.** Fork PRs never get OIDC tokens, but a teammate's PR branch could change the workflow. A separate Reader-only identity for PR plans would close that.
- **Discord webhook URL is stored in the Logic App definition.** Anyone with read access to the Logic App can see it. Production would keep it in Key Vault and have the Logic App read it with a managed identity.
- **Two alert paths.** Sentinel creates the incident, and a separate Azure Monitor alert sends the Discord message, both from one shared query. Wiring Discord directly to Sentinel needs a Sentinel-triggered playbook and extra role grants for Sentinel's own service principal, which I chose not to automate yet.
- **Defender for Containers isn't used.** Its runtime protection covers Kubernetes clusters, not Azure Container Apps ([security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/azure-container-apps-security-baseline#posture-and-vulnerability-management)). It could scan ACR images, but Grype already blocks vulnerable images before they reach ACR.
- **OIDC subject format.** Azure federated credentials match the subject as an exact string. If the repo moves to GitHub's immutable subject format, all three credentials have to be deleted and recreated. See [GitHub's changelog](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/).
- **`.terraform.lock.hcl` is gitignored.** HashiCorp recommends committing it so every run uses the exact same provider build. The provider version is pinned to `4.79.0`, which limits the risk.

#### You can read all my run-ins and mishaps in my knowledge base → [Azure Appsec Pipeline](https://notes.artistuniverse.tech/personal_projects/azure_appsec_pipeline/)
