tiller:
	kubectl apply -f 01-tiller-service-account.yml
	helm init --service-account tiller
	helmfile repos

test:
	helmfile  -l name=blackbox-exporter-servicemonitor template

clickhouse:
	kubectl apply -f https://raw.githubusercontent.com/Altinity/clickhouse-operator/0.6.0/manifests/operator/clickhouse-operator-install.yaml

minio:
	helmfile --kube-context kube-gitlab -l name=minio apply  --skip-deps

mysql:
	helmfile -l name=mysql-operator  apply  --skip-deps

prom:
	helmfile -l name=prometheus  apply  --skip-deps

telegram:
	helmfile -l name=telegram-bot apply  --skip-deps
loki:
	helmfile -l name=loki        apply  --skip-deps
rook:
	helmfile -l name=rook        apply  --skip-deps || helmfile -l name=rook        apply  --skip-deps
	kubectl apply -f rook-manifects/cluster.yaml
	kubectl apply -f rook-manifects/storageclass.yaml
	kubectl patch storageclasses.storage.k8s.io rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl apply -f rook-manifects/toolbox.yaml

ingress:
	helmfile  -l name=nginx-ingress  apply --skip-deps

cert:
	kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
	kubectl wait --for condition=established --timeout=60s crd/ClusterIssuer
	kubectl apply -f ClusterIssuer.yaml
	helmfile  -l name=cert  apply --skip-deps

all: ingress cert rook loki telegram prom mysql clickhouse



install-client-binaries:
	curl -fsSL https://storage.googleapis.com/kubernetes-helm/helm-v2.14.3-linux-amd64.tar.gz |   sudo tar -xvz --strip=1 -f - -C /usr/local/bin/ linux-amd64/helm
	helm plugin install https://github.com/databus23/helm-diff --version master
	wget -O  /usr/local/bin/helmfile https://github.com/roboll/helmfile/releases/download/v0.80.2/helmfile_linux_amd64
	wget -O  /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.1.0/kustomize_3.1.0_linux_amd64
	helm plugin install https://github.com/futuresimple/helm-secrets
	#helm plugin install https://github.com/mumoshu/helm-x #exits with error, workaround below
	mkdir -p  ~/.helm/plugins/helm-x/bin/
	curl -fsSL https://github.com/mumoshu/helm-x/releases/download/v0.7.2/helm-x_0.7.2_linux_amd64.tar.gz | tar -xvz -f - -C ~/.helm/plugins/helm-x/bin/ helm-x
