# DEVOPS-4: Troubleshoot a broken Nomad deployment (nginx)

## 1. Root Causes Identified
Upon inspecting the repository (nginx.hcl, Dockerfile, and index.html) and running the initial deployment, four configuration issues were identified:
1. *Invalid Datacenter Name:* nginx.hcl specified datacenters = ["yourdatacenter-name"], causing Nomad evaluation to fail with "No nodes were eligible for evaluation" since the local cluster datacenter is dc1.
2. *Non-existent Placeholder Docker Image:* The job used image = "yourdockerhubusername/nginx-app:latest", which failed with a Docker driver pull access denied error.
3. *Missing Port Mapping in Task Config:* Although port "http" { to = 80 } was defined in the network block, ports = ["http"] was missing from the Docker config block, preventing host-to-container port binding.
4. *Missing Health Check Endpoint & Low Memory:* The Consul service health check targeted path = "/health", which returned 404 Not Found because no dedicated health check endpoint was configured in Nginx, and memory allocation was set too low (50 MB).

## 2. Debugging Process
1. *Initial Deployment & Job Inspection:* Ran nomad job run nginx.hcl followed by nomad job status nginx-app, which revealed Placed: 0 due to ineligible nodes.
2. *Allocation & Event Log Analysis:* After fixing the datacenter to dc1, inspected failed allocations using nomad alloc status <alloc-id> and checked Recent Events, which pinpointed the Driver Failure: Failed to pull image error.
3. *Configuration & Service Audit:* Reviewed nginx.hcl line-by-line to verify network port bindings, Nginx routing configuration, resource limits, and Consul HTTP health check endpoints.

## 3. Fix Implemented
* Changed datacenters from ["yourdatacenter-name"] to ["dc1"].
* Replaced the invalid image with nginx:alpine and mounted the custom index.html (local/index.html:/usr/share/nginx/html/index.html).
* Created a dedicated /healthz endpoint in Nginx via a custom default.conf template (local/default.conf:/etc/nginx/conf.d/default.conf) returning 200 OK.
* Added ports = ["http"] inside the Docker task config block.
* Updated the Consul health check path to "/healthz" and increased memory resources to 128 MB.

## 4. Verification
* *Nomad Status:* nomad job status nginx-app confirms Status = running with Desired: 1, Placed: 1, Healthy: 1.
* *Health Endpoint & Consul Discovery:* curl -i http://localhost:<port>/healthz returns HTTP/1.1 200 OK, and consul catalog services / Consul Web UI (port 8500) show nginx-app passing the /healthz health check.
* *Browser Access:* Accessed the dynamically assigned host port via browser and verified both / and /healthz endpoints respond properly.
<img width="1365" height="693" alt="Picture 1" src="https://github.com/user-attachments/assets/3e8514ee-f3b4-4f2a-9746-70186e97428f" />
<img width="1365" height="690" alt="Picture 2" src="https://github.com/user-attachments/assets/051d3038-adf1-4f57-a914-8e6193e4cf13" />
