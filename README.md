# DevOps Assessment VIII - Runbook (ISWE406P)

Three projects, same workflow. Replace the placeholders **once** in each folder:

| Placeholder | Where | Replace with |
|---|---|---|
| `suhaib08` | `deployment.yaml`, `Jenkinsfile` | your Docker Hub username |
| `YOUR_GITHUB_USERNAME` | `Jenkinsfile` | your GitHub username |

| Q | Folder | Image / Deployment | Replicas | NodePort |
|---|---|---|---|---|
| 1 | `q1-placement-portal` | `placement-portal` | 2 | 30081 |
| 2 | `q2-bookstore` | `bookstore` | 3 | 30082 |
| 3 | `q3-event-portal` | `event-portal` | 3 | 30083 |

Take screenshots at every step marked **[SS]**. Commands below use Q1; swap names for Q2/Q3.

## 0. One-time setup
1. Install Docker Desktop, then **Settings > Kubernetes > Enable Kubernetes**. Wait until it shows "running".
2. Check: `kubectl get nodes` shows `docker-desktop   Ready` **[SS]**
3. Install Jenkins (Windows installer or `docker run`). On the Jenkins machine, `docker` and `kubectl` must work from a terminal. If Jenkins runs as a Windows service, run the service as your own user.
4. Create a Docker Hub account and a **Personal Access Token** (Account Settings > Security).
5. Create an empty GitHub repo per question (`placement-portal`, `bookstore`, `event-portal`).

## 1. Git repository
```bash
cd q1-placement-portal
git init
git add .
git commit -m "Initial placement portal"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/placement-portal.git
git push -u origin main
```
**[SS]** repo showing index.html, Dockerfile, deployment.yaml, Jenkinsfile.

## 2-3. Build image, run locally, verify
```bash
docker build -t suhaib08/placement-portal:v1 .
docker run -d -p 8080:80 --name portal-test suhaib08/placement-portal:v1
```
Open http://localhost:8080 **[SS]**, then clean up: `docker rm -f portal-test`

## 4. Push to Docker Hub
```bash
docker login -u suhaib08      # paste the access token
docker push suhaib08/placement-portal:v1
```
**[SS]** image on hub.docker.com. This `v1` is the first stable release the cluster starts from.

## 5-6, 9. Kubernetes Deployment + NodePort Service
`deployment.yaml` contains both the Deployment and the NodePort Service.
```bash
kubectl apply -f deployment.yaml
kubectl get deployment
kubectl get pods          # 2 pods (Q1) / 3 pods (Q2, Q3), all Running
kubectl get svc
```
## 10-11. Verify
Open http://localhost:30081 **[SS]**, and **[SS]** `kubectl get pods` showing all Running.

## 7. Jenkins credentials
Manage Jenkins > Credentials > System > Global > Add Credentials:
1. **Docker Hub**: Kind = *Username with password*, ID = `dockerhub-creds`, password = your access token.
2. **Kubernetes config**: Kind = *Secret file*, ID = `kubeconfig`, upload `~/.kube/config` (Windows: `C:\Users\<you>\.kube\config`). **[SS]**

Note: Docker Desktop's kubeconfig points at `127.0.0.1` / `kubernetes.docker.internal`, which works when Jenkins runs directly on the same machine. If Jenkins runs in a container, this will not connect without extra network setup.

## 8. Jenkins pipeline
New Item > **Pipeline** > Pipeline script from SCM > Git > your repo URL, branch `*/main`, Script Path `Jenkinsfile`. Click **Build Now** (the first run registers the `FAULTY_BUILD` parameter; later use **Build with Parameters**).

Stages: Clone Code > Build Docker Image > Test Application > Push Image > Deploy to Kubernetes (with rollout check + auto-rollback) > Verify Pods. Q2 adds a Security Scan stage. **[SS]** green stage view.

## Faulty release and automatic rollback (all three questions)
Pipeline runs with a good build first, so a stable release exists. Then:
1. **Build with Parameters**, tick `FAULTY_BUILD`, run.
2. The image builds and pushes fine, but the container crashes on start (invalid nginx config). The new pod never becomes Ready, so the rollout stalls. Because `maxUnavailable: 0`, the old pods keep serving traffic throughout.
3. After 90 seconds `kubectl rollout status` fails, the pipeline runs `kubectl rollout undo` and the build is marked **failed** with the message "Rolled back to previous stable version". **[SS]** console output showing the failure and rollback.
4. Prove it:
```bash
kubectl rollout history deployment/placement-portal
kubectl get pods                       # all Running again on the stable image
kubectl describe deployment placement-portal | findstr Image    # Linux: grep Image
```
Open http://localhost:30081, still working **[SS]**. While the faulty rollout is in progress, `kubectl get pods` shows a pod in `CrashLoopBackOff` **[SS]**; run it in a second terminal during the build.

Manual alternative: `docker build --build-arg FAULTY=true -t USER/placement-portal:bad .`, push, `kubectl set image deployment/placement-portal placement-portal=USER/placement-portal:bad`, watch it fail, then `kubectl rollout undo deployment/placement-portal`.

---
## Q2 extras (steps 10-14: modify, rebuild, push, update)
In `q2-bookstore/index.html`, replace the line `<!-- NEW FEATURE HERE -->` with:
```html
<div class="panel" id="thanks">
  <h2>Thank You!</h2>
  <p>Thank you for shopping with PageTurner. Every order supports local libraries.</p>
  <p style="margin-top:8px"><b>Customer rating summary:</b> 4.7 / 5 from 1,284 readers (92% recommend)</p>
</div>
```
Then either push to GitHub and run the Jenkins job, or manually:
```bash
docker build -t suhaib08/bookstore:v2 .
docker push suhaib08/bookstore:v2
kubectl set image deployment/bookstore bookstore=suhaib08/bookstore:v2
kubectl rollout status deployment/bookstore
kubectl get deployment bookstore
kubectl get pods
```
Open http://localhost:30082 and confirm the Thank You section **[SS]**.

Gates in this pipeline: (1) `tests/check.sh` runs during docker build (needs 6+ books, search, cart, tracking, prices, availability labels, no inline credentials); (2) same test again on the built image; (3) Trivy scan blocks CRITICAL CVEs if Trivy is installed (skipped otherwise, and it says so in the log); (4) rollout health gate with auto-rollback. To demo gate 1, delete five books from the HTML and run the build, which fails before anything reaches Docker Hub.

## Q3 extras (steps 9-13: modify, re-trigger, verify)
The question says "placement webpage", but this is the event portal, so add a new event. In `q3-event-portal/index.html`, replace `<!-- NEW FEATURE HERE -->` with:
```html
<section id="newevent">
  <h2>New Event Added</h2>
  <div class="card event"><span class="badge">Workshop</span><h3>Cloud Security Bootcamp</h3>
  <p>15 Dec 2026 &middot; Computer Lab 3 &middot; Limit: 50 seats</p></div>
</section>
```
```bash
git add . && git commit -m "Add Cloud Security Bootcamp" && git push
```
Jenkins picks it up (Poll SCM every 2 minutes) or click **Build Now**. Show the console log: clones the new commit, builds, pushes, deploys. Then `kubectl get pods` (3 Running) **[SS]** and open http://localhost:30083 **[SS]**.

## Troubleshooting
- `ImagePullBackOff`: wrong Docker Hub username in `deployment.yaml`, or `v1` was not pushed.
- Jenkins "docker/kubectl not recognized": restart the Jenkins service after installing, or add them to the system PATH.
- Jenkins cannot reach the cluster: re-copy `~/.kube/config` into the credential after enabling Kubernetes.
- Port already used: change `nodePort` (range 30000-32767).
