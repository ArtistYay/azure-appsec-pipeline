# Azure Appsec Pipeline
Intersecting DevSecOps to security operations

## Why This Exists

Most companies have a CI/CD pipeline and a SIEM, but the two don't talk to each other. The pipeline knows what got deployed and whether it passed a scan. The SIEM knows something went wrong at runtime. Neither one has the other's context, and that gap is where real incidents slip through. A vulnerable image gets deployed, it starts misbehaving in production, and the security team investigating it has no idea what pipeline shipped it, whether it was scanned, or what changed right before things went sideways.

This project closes that gap. The application layer generates structured logs the moment something happens. Docker captures them, Azure Monitor ships them to Sentinel. The pipeline itself generates its own events, scan results, deployment status, that land in the same place. So instead of a SIEM seeing an isolated alert, it sees the alert *and* the code that produced it.

The Terraform layer does the same thing for infrastructure. Instead of every developer hand-rolling their own network rules, encryption settings, and identity permissions, they call a module that already has secure defaults built in. Azure Policy sits on top as the enforcement layer, even if someone edits a module and strips out a control, the deployment gets blocked before it ever reaches production.

**What this means for a business:** the cost of a security incident isn't just the incident itself, it's the time spent figuring out how it happened. A pipeline that ties deployment context to runtime detection turns "something's wrong, we don't know what" into "here's exactly what shipped, when, and what it looked like passing every gate along the way." That's the difference between an incident response that takes hours and one that takes days.

I built this to prove I understand how these pieces actually fit together, not just that I know which button turns on Defender for Cloud. Anyone can enable a managed service. Fewer people can architect the pipeline that feeds it.

## Built With
- Python
- Docker
- Terraform

## Prerequisites: One-Time Manual Setup

This project uses a `data` source (not a `resource`) for the resource group. That's a deliberate choice — GitHub Actions authenticates to Azure using OIDC, and the identity behind that authentication has to live in a resource group that Terraform never destroys. Otherwise, tearing down infrastructure for testing would also delete the very credentials the pipeline needs to run.

Before running this project, someone needs to manually create, once:

1. The resource group (`rg-appsec-dev` or your chosen name)

```bash
az group create --name rg-appsec-dev --location eastus
```

2. A user-assigned managed identity for GitHub Actions

```bash
az identity create --name id-github-actions-appsec --resource-group rg-appsec-dev
```

3. A federated identity credential linking that identity to this GitHub repo

```bash
    az identity federated-credential create \
  --name github-actions-federated-cred \
  --identity-name id-github-actions-appsec \
  --resource-group rg-appsec-dev \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:YOUR_GITHUB_USERNAME/azure-appsec-pipeline:ref:refs/heads/main \
  --audiences api://AzureADTokenExchange
```

4. A role assignment (Contributor or scoped custom role) granting that identity permission on the resource group

```bash
az role assignment create \
  --assignee <clientId-from-step-2> \
  --role Contributor \
  --scope /subscriptions/<your-subscription-id>/resourceGroups/rg-appsec-dev # this repo owns the identity.
```

Terraform reads the resource group via a data source, it will never create or destroy it. `terraform destroy` only tears down what's *inside* the resource group.

#### You can read all my run-ins and mishaps in my knowledge base → [Azure Appsec Pipeline](https://notes.artistuniverse.tech/personal_projects/azure_appsec_pipeline/)