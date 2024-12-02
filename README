#Build and push images to Docker Hub
# In service1 directory
docker build -t gcr.io/clever-spirit-417020/service1:latest .
docker push gcr.io/clever-spirit-417020/service1:latest
kubectl rollout restart deploy service1

# In service2 directory
docker build -t gcr.io/clever-spirit-417020/service2:latest .
docker push gcr.io/clever-spirit-417020/service2:latest


#Apply the deployments and services to your Kubernetes cluster:
kubectl apply -f k8s-manifests/service1-deployment.yaml
kubectl apply -f k8s-manifests/service1-service.yaml
kubectl apply -f k8s-manifests/service2-deployment.yaml
kubectl apply -f k8s-manifests/service2-service.yaml

#Apply the ingress to the cluster:
kubectl apply -f k8s-manifests/ingress.yaml

# rollout
kubectl rollout restart deploy service1

# Deploy using the Helm Chart
helm install helm-dir ./helm-dir

#You can update your deployment with:
helm upgrade helm-dir ./helm-dir
or
helm upgrade -f panda.yaml happy-panda bitnami/wordpress

# Traefik
### Upgrade traefik
helm upgrade traefik traefik/traefik -f treafik.yaml
### View traefik configuration
kubectl describe service traefik -n default
# Install Traefik:
helm install traefik traefik/traefik --set service.type=LoadBalancer
# If you need to get the current values from your deployment, run:
helm get values traefik -n default > values.yaml


#Check if all pods and services are running properly:
helm list  Lists all Helm releases and their status.
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl exec -it <pod_name> -- printenv
kubectl logs <pod_name>

# Delete the Ingress Resource
# Option 1: Delete the Ingress Resource
# This will stop Traefik from routing traffic to your services based on the specified ingress rules. However, Traefik will still be running in your cluster, which may be useful if you plan to reconfigure or redeploy it.
kubectl delete ingress service1-ingress service2-ingress

# Option 2: Delete the Traefik Deployment
#If you want to completely stop Traefik, you can delete its deployment.
#First, identify the namespace where Traefik is deployed (usually traefik or kube-system).
#Delete the Traefik deployment and any associated resources:

kubectl delete deployment -n <traefik-namespace> traefik
Replace <traefik-namespace> with the namespace where Traefik is installed (e.g., traefik or kube-system).

#Option 3: Scale Down the Traefik Deployment
#Scaling down Traefik to zero replicas is a quick way to stop it temporarily without deleting the deployment.

kubectl scale deployment -n <traefik-namespace> traefik --replicas=0

#To restart Traefik, simply scale it back up:
kubectl scale deployment -n <traefik-namespace> traefik --replicas=1

#Option 4: Remove Traefik Ingress Controller Completely
#If you want to completely remove Traefik from your cluster, you can delete all Traefik-related resources (e.g., deployment, service, and config maps). Make sure to check Traefik’s documentation for any additional resources that might need to be removed.
kubectl delete all -n <traefik-namespace> -l app=traefik


## To roll back a deployment in Kubernetes to a previous version, you can use the following command:
kubectl rollout undo deployment/service1

##Rollback to a Specific Revision: If you want to roll back to a specific revision, you can first list the revision history to identify which one you want to roll back to:
kubectl rollout history deployment/service1

## This will show you a list of revisions. Then, you can roll back to a specific revision using:
kubectl rollout undo deployment/service1 --to-revision=<revision_number>
Replace <revision_number> with the desired revision number from the history.

## Check the Status of the Rollback
To ensure the rollback was successful, check the status of the deployment:
kubectl rollout status deployment/service1
View the Current State
You can also view the current state of your deployment to verify the rollback:
kubectl get deployment service1

#Notes for Helm Upgrade and Deletion
#Update/Upgrade Your Deployment If you make changes to your Helm chart (e.g., update the values.yaml or other configuration files), you can upgrade your deployment using:
helm upgrade my-express-app ./my-express-app

#Delete the Deployment If you want to remove your deployment, use:
helm uninstall my-express-app

#Troubleshooting
#Pod Errors: Check the logs of your pods if they’re not running correctly:
kubectl logs <pod-name>

#Ingress Issues: Ensure Traefik is configured correctly and the ingress rules are working as expected.
#Helm Errors: Use helm status my-express-app to get more details about your deployment.

#How to Check IngressRoute Resources
#To list and get details about Traefik's IngressRoute resources, use the following commands:

#List All IngressRoutes

kubectl get ingressroute
#This will show you all the IngressRoute resources that have been deployed in your Kubernetes cluster.

#Get Details of a Specific IngressRoute
kubectl describe ingressroute <name-of-your-ingressroute>
#Replace <name-of-your-ingressroute> with the name of your IngressRoute object to get more details, including any potential issues.

#Steps to Troubleshoot
#Check if Traefik is Running Ensure that the Traefik ingress controller is up and running:

kubectl get pods -n traefik

#If Traefik is not running, check your Traefik deployment configuration and ensure it’s correctly installed and deployed.
#Verify Traefik Custom Resource Definitions (CRDs) Check if the necessary CRDs for Traefik (IngressRoute, Middleware, etc.) are installed:

kubectl get crd
You should see resources like ingressroutes.traefik.io, middlewares.traefik.io, and other Traefik-related CRDs.

Review Your IngressRoute Configuration

Open the k8s-manifests/ingress.yaml file and double-check that the configuration matches your requirements.
Ensure that the IngressRoute is correctly pointing to your services and using the right entry points (e.g., web for HTTP or websecure for HTTPS).

#Check Logs for Errors Check the logs of the Traefik ingress controller for any errors or warnings:
kubectl logs -n traefik <traefik-pod-name>
Replace <traefik-pod-name> with the name of your Traefik pod.


### Create a static address
gcloud compute addresses create websitestatic2 --region=europe-west1
### Get addresses
gcloud compute addresses list

# Minify CSS
css-minify --file filename
css-minify -d sourcedir -o distdir

