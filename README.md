# DEVOPS-4: Troubleshoot a broken Nomad deployment (nginx)

## 1. Root Causes Identified
Upon inspecting the repository (nginx.hcl, Dockerfile, and index.html) and running the initial deployment, four configuration issues were identified:
1. *Invalid Datacenter Name:* nginx.hcl specified datacenters = ["yourdatacenter-name"], causing Nomad evaluation to fail with "No nodes were eligible for evaluation" since the local cluster datacenter is dc1.
2. *Non-existent Placeholder Docker Image:* The job used image = "yourdockerhubusername/nginx-app:latest", which failed with a Docker driver pull access denied error.
3. *Missing Port Mapping in Task Config:* Although port "http" { to = 80 } was defined in the network block, ports = ["http"] was missing from the Docker config block, preventing host-to-container port binding.
4. *Invalid Consul Health Check Path & Low Memory:* The Consul service health check targeted path = "/health", which returns 404 Not Found on default Nginx (causing unhealthy status), and memory allocation was set too low (50 MB).

## 2. Debugging Process
1. *Initial Deployment & Job Inspection:* Ran nomad job run nginx.hcl followed by nomad job status nginx-app, which revealed Placed: 0 due to ineligible nodes.
2. *Allocation & Event Log Analysis:* After fixing the datacenter to dc1, inspected failed allocations using nomad alloc status <alloc-id> and checked Recent Events, which pinpointed the Driver Failure: Failed to pull image error.
3. *Configuration & Service Audit:* Reviewed nginx.hcl line-by-line to verify network port bindings, resource limits, and Consul HTTP health check endpoints.

## 3. Fix Implemented
* Changed datacenters from ["yourdatacenter-name"] to ["dc1"].
* Replaced the invalid image with nginx:alpine and mounted the custom index.html using Nomad's template and volumes configuration (local/index.html:/usr/share/nginx/html/index.html).
* Added ports = ["http"] inside the Docker task config block.
* Updated the Consul health check path from "/health" to "/" and increased memory resources to 128 MB.

## 4. Verification
* *Nomad Status:* nomad job status nginx-app confirms Status = running with Desired: 1, Placed: 1, Healthy: 1.
* *Consul Service Discovery:* consul catalog services and the Consul Web UI (port 8500) show nginx-app registered with a passing health check.
* *Browser Access:* Accessed the dynamically assigned host port via browser and verified the custom HTML page loads properly.
<img width="1355" height="646" alt="Screenshot (10)" src="https://github.com/user-attachments/assets/5830e8a6-6593-4f0e-b995-05f468ed0b0a" />
<img width="1360" height="692" alt="Screenshot (11)" src="https://github.com/user-attachments/assets/4612c090-646a-48df-8e0d-472f867bc334" />
