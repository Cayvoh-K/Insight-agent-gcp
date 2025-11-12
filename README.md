# Insight-Agent MVP

A secure, serverless API deployed on **Google Cloud Platform (GCP)**, fully automated using **Terraform** and **GitHub Actions**.  
The service performs basic text analysis on customer feedback.

---

## Architecture Overview

```
[ GitHub Actions ]
       |
       v
[ Docker Container ]
       |
       v
[ Artifact Registry ] ---> [ Cloud Run (Serverless API) ]
       |
       v
Authorized Users / CI/CD access via IAM
```

- **Cloud Run**: Serverless container execution.
- **Artifact Registry**: Stores Docker images.
- **Terraform**: Infrastructure-as-Code (IaaC) for reproducible deployments.
- **GitHub Actions**: CI/CD pipeline for building, testing, and deploying.
- **Service Accounts & IAM**: Secure access to Cloud Run.

---

## Design Decisions

- **Cloud Run** chosen for serverless scalability and easy integration with GCP services.  
- **Internal-only ingress** ensures the service is not publicly exposed.  
- **IAM roles (`roles/run.invoker`)** limit who can invoke the API.  
- **GitHub Actions** automates deployment with secrets stored safely in repository settings.  
- **Terraform** ensures consistent, repeatable infrastructure provisioning.

---

## Setup and Deployment Instructions

### Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed.
- [Docker](https://www.docker.com/get-started) installed and running.
- GitHub repository with **Secrets**:
  - `GCP_PROJECT_ID` → your GCP project ID (`insight-agent-mvp`)
  - `GCP_REGION` → `us-central1`
  - `GCP_SA_KEY` → JSON key of `github-actions-sa` service account

---

### Steps

1. **Clone the repository**
```bash
git clone https://github.com/<your-username>/Insight-agent-gcp.git
cd Insight-agent-gcp
```

2. **Initialize Terraform**
```bash
terraform -chdir=terraform init
```

3. **Apply Terraform to provision resources**
```bash
terraform -chdir=terraform apply \
  -var="project_id=<your-project-id>" \
  -var="region=us-central1" \
  -var="service_name=insight-agent-service" \
  -var="image=us-central1-docker.pkg.dev/<project-id>/insight-agent-repo/insight-agent:latest"
```

4. **Check Cloud Run URL**
```bash
gcloud run services describe insight-agent-service \
  --region us-central1 \
  --format="value(status.url)"
```

5. **Test the API**
```bash
SERVICE_URL="<Cloud-Run-URL>/analyze"
ID_TOKEN=$(gcloud auth print-identity-token)

curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -d '{"text": "I love cloud engineering!"}' \
  $SERVICE_URL
```

Expected response:
```json
{
  "original_text": "I love cloud engineering!",
  "word_count": 4,
  "character_count": 25
}
```

---

## CI/CD Pipeline (GitHub Actions)

- Triggered on push to `main` branch.  
- Steps:
  1. Lint Python and Terraform code.
  2. Build Docker image.
  3. Push image to Artifact Registry.
  4. Deploy Cloud Run using Terraform with updated image.

---

## Security

- Cloud Run service is **internal-only**.
- Access restricted via **IAM roles**, not public.  
- GitHub Actions uses a **dedicated service account** (`github-actions-sa`) with least privilege (`roles/run.invoker`).  
- Service account key is stored in **GitHub Secrets**, never committed to the repository.

---

## Next Steps / Enhancements

- Add more advanced text analysis or AI features.  
- Integrate logging and monitoring with **Cloud Logging** and **Cloud Monitoring**.  
- Add automated tests for API responses.

---
