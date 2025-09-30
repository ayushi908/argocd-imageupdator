# ArgoCD Image Updater + GitHub Actions PoC 🚀

This repository demonstrates a **CI/CD workflow** using:

- **GitHub Actions** → Build & push Docker image to DockerHub  
- **ArgoCD Image Updater** → Automatically update Kubernetes manifests with new image tag  
- **ArgoCD** → Sync & deploy changes to a Kubernetes cluster 

├── .github/workflows/ci.yml # GitHub Actions workflow
├── app/ # Application source code
│ ├── package.json
│ └── server.js
├── k8s/ # Kubernetes manifests
│ ├── deployment.yaml
│ ├── service.yaml
│ └── kustomization.yaml
├── argocd-app/ # ArgoCD Application manifest
│ └── application.yaml
├── Dockerfile
└── README.md


## 🔹 Prerequisites

- Docker Desktop installed with **Kubernetes enabled**  
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed  
- GitHub account with a repo to test the workflow  
- DockerHub account and repository (e.g., `ayushbhagat/hello-world-app`)  

⚙️ Step 1: Enable Kubernetes in Docker Desktop

1. Open **Docker Desktop → Settings → Kubernetes**  
2. Enable Kubernetes and click **Apply & Restart**  
3. Verify cluster is running:

```bash
kubectl cluster-info
kubectl get nodes

Step 2: Install MetalLB (for LoadBalancer service locally)
Apply MetalLB namespace and components:
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.13/config/manifests/metallb-native.yaml

Configure IP address pool (replace with your local subnet):
# metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
  - 127.0.0.1/32
Apply it 
kubectl apply -f metallb-config.yaml

Step3: Install ArgoCD
Create namespace:
kubectl create namespace argocd

Install ArgoCD:
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Expose ArgoCD server (LoadBalancer):
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

Login to ArgoCD:
kubectl get pods -n argocd
kubectl get svc -n argocd

Default password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

Install Argocd Image updator
kubectl create namespace argocd-image-updater
kubectl apply -n argocd-image-updater -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

Step 5: Create Kubernetes Manifests
Create deployment.yaml service.yaml kustomization.yaml

Step 6: Create ArgoCD Application
File: argocd-app/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-world-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/ayushi908/argocd-imageupdator
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

Apply it:
kubectl apply -f argocd-app/application.yaml -n argocd

Step 7: Configure GitHub Actions
File: .github/workflows/ci.yml

Step 8: Test the Flow

Make changes in app/ → commit & push.
GitHub Actions builds & pushes a new Docker image.
ArgoCD Image Updater updates k8s/kustomization.yaml with new image tag.
ArgoCD syncs → deployment updated in Kubernetes.

kubectl get pods
kubectl get svc

Check the pods in default namespace
kubectl get pods -n default


(create Git credentials (git-creds) for ArgoCD Image Updater)
so it can commit back to your repository, and then use them in application.yaml
Step 1: Create Fine-Grained PAT on GitHub
Go to GitHub → Settings → Developer settings → Personal Access Tokens → Fine-grained tokens → Generate new token
Repository access → Choose Only select repositories → select your repository (argocd-imageupdator)

Permissions:
Actions- we are uisng github actions
Admistrator
codespace
commit-status
Contents → Read & write (allows ArgoCD to update files)
Pull requests → Read & write (optional, if needed)
Workflows → Read & write (if GitHub Actions triggers are required)
Expiration → Set as per your policy (e.g., 90 days or custom)
Click Generate token → copy it (you won’t see it again).

Step 2: Create Kubernetes Secret for ArgoCD
Replace <GITHUB_USERNAME> with your GitHub username and <FINE_GRAINED_PAT> with the token you just generated:

kubectl create secret generic git-creds \
  --from-literal=username=<GITHUB_USERNAME> \
  --from-literal=password=<FINE_GRAINED_PAT> \
  -n argocd

✅ This creates a secret git-creds in the argocd namespace.

Step 3: Reference Secret in Application YAML
In argocd-app/application.yaml:

Step 4: Verify
Check the secret exists:
kubectl get secret git-creds -n argocd -o yaml

Make a small change in your repo → ArgoCD Image Updater should be able to commit it back using this fine-grained PAT.
