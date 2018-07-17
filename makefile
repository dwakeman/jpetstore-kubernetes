# update based on your IBM Container Registry namespace
NAMESPACE=davewakeman

# update based on your Ingress Subdomain (use `ibmcloud cs cluster-get <CLUSTERNAME>` to obtain)
INGRESSSUBDOMAIN=jpetstore.dw-petstore-03.us-south.containers.appdomain.cloud

# the IBM container registry
REGISTRY=registry.ng.bluemix.net

TIMESTAMP="$(shell date)"

build-petstore:
	cd jpetstore && docker build . -t $(REGISTRY)/$(NAMESPACE)/jpetstoreweb
	docker push $(REGISTRY)/$(NAMESPACE)/jpetstoreweb
	cd jpetstore/db && docker build . -t $(REGISTRY)/$(NAMESPACE)/jpetstoredb
	docker push $(REGISTRY)/$(NAMESPACE)/jpetstoredb

build-mmssearch:
	cd mmssearch && docker build . -t $(REGISTRY)/$(NAMESPACE)/mmssearch
	docker push $(REGISTRY)/$(NAMESPACE)/mmssearch

create-secrets:
	cd mmssearch && kubectl create secret generic mms-secret --from-file=mms-secrets=./mms-secrets.json
	
deploy-using-helm:
	cd helm && helm install --name jpetstore ./modernpets
	cd helm && helm install --name mmssearch ./mmssearch

remove-deployments:
	helm delete jpetstore --purge
	helm delete mmssearch --purge

remove-images:
	ibmcloud cr image-rm $(REGISTRY)/$(NAMESPACE)/jpetstoredb
	ibmcloud cr image-rm $(REGISTRY)/$(NAMESPACE)/jpetstoreweb
	ibmcloud cr image-rm $(REGISTRY)/$(NAMESPACE)/mmssearch

remove-secrets:
	kubectl delete secret mms-secret

rolling-update:
	cd mmssearch && docker build . -t $(REGISTRY)/$(NAMESPACE)/mmssearch
	docker push $(REGISTRY)/$(NAMESPACE)/mmssearch
	kubectl patch deployment mmssearch-mmssearch -p '{"spec":{"template":{"metadata":{"annotations":{"date":$(TIMESTAMP)}}}}}'

scale-up:
	kubectl scale --replicas=6 deployment jpetstore-modernpets-jpetstoreweb
	kubectl rollout status deployment jpetstore-modernpets-jpetstoreweb
	kubectl get po -l app=modernpets-jpetstoreweb

scale-down:
	kubectl scale --replicas=2 deployment jpetstore-modernpets-jpetstoreweb
	kubectl rollout status deployment jpetstore-modernpets-jpetstoreweb
	kubectl get po -l app=modernpets-jpetstoreweb