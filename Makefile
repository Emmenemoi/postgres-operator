RELTMPDIR=/tmp/release.$(CO_VERSION)
RELFILE=/tmp/postgres-operator.$(CO_VERSION).tar.gz

#======= Safety checks =======
check-go-vars:
ifndef GOPATH
	$(error GOPATH is not set)
endif
ifndef GOBIN
	$(error GOBIN is not set)
endif

#======= Main functions =======
macpgo:	check-go-vars
	cd pgo && env GOOS=darwin GOARCH=amd64 go build pgo.go && mv pgo $(GOBIN)/pgo-mac

gendeps: 
	godep save \
	github.com/crunchydata/postgres-operator/apis/cr/v1 \
	github.com/crunchydata/postgres-operator/util \
	github.com/crunchydata/postgres-operator/operator \
	github.com/crunchydata/postgres-operator/operator/backup \
	github.com/crunchydata/postgres-operator/operator/cluster \
	github.com/crunchydata/postgres-operator/operator/pvc \
	github.com/crunchydata/postgres-operator/controller \
	github.com/crunchydata/postgres-operator/client \
	github.com/crunchydata/postgres-operator/pgo/cmd \
	github.com/crunchydata/postgres-operator/apiservermsgs \
	github.com/crunchydata/postgres-operator/apiserver \
	github.com/crunchydata/postgres-operator/apiserver/backupservice \
	github.com/crunchydata/postgres-operator/apiserver/cloneservice \
	github.com/crunchydata/postgres-operator/apiserver/clusterservice \
	github.com/crunchydata/postgres-operator/apiserver/labelservice \
	github.com/crunchydata/postgres-operator/apiserver/loadservice \
	github.com/crunchydata/postgres-operator/apiserver/policyservice \
	github.com/crunchydata/postgres-operator/apiserver/pvcservice \
	github.com/crunchydata/postgres-operator/apiserver/upgradeservice \
	github.com/crunchydata/postgres-operator/apiserver/userservice \
	github.com/crunchydata/postgres-operator/apiserver/util \
	github.com/crunchydata/postgres-operator/apiserver/versionservice 
setup:
	./bin/get-deps.sh
deployoperator:
	cd deploy && ./deploy.sh
main:	check-go-vars
	go install postgres-operator.go
runmain:	check-go-vars
	postgres-operator --kubeconfig=/etc/kubernetes/admin.conf
runapiserver:	check-go-vars
	apiserver --kubeconfig=/etc/kubernetes/admin.conf
apiserver:	check-go-vars
	go install apiserver.go
pgo:	check-go-vars
	cd pgo && go install pgo.go
clean:	check-go-vars
	rm -rf $(GOPATH)/pkg/* $(GOBIN)/postgres-operator $(GOBIN)/apiserver $(GOBIN)/*pgo
apiserverimage:	check-go-vars
	go install apiserver.go
	cp $(GOBIN)/apiserver bin/
	docker build -t pgo-apiserver -f $(CO_BASEOS)/Dockerfile.pgo-apiserver.$(CO_BASEOS) .
	docker tag pgo-apiserver crunchydata/pgo-apiserver:$(CO_BASEOS)-$(CO_VERSION)
postgres-operator:	check-go-vars
	go install postgres-operator.go
operatorimage:	check-go-vars
	go install postgres-operator.go
	cp $(GOBIN)/postgres-operator bin/postgres-operator/
	docker build -t postgres-operator -f $(CO_BASEOS)/Dockerfile.postgres-operator.$(CO_BASEOS) .
	docker tag postgres-operator crunchydata/postgres-operator:$(CO_BASEOS)-$(CO_VERSION)
lsimage:
	docker build -t pgo-lspvc -f $(CO_BASEOS)/Dockerfile.pgo-lspvc.$(CO_BASEOS) .
	docker tag pgo-lspvc crunchydata/pgo-lspvc:$(CO_BASEOS)-$(CO_VERSION)
loadimage:
	docker build -t pgo-load -f $(CO_BASEOS)/Dockerfile.pgo-load.$(CO_BASEOS) .
	docker tag pgo-load crunchydata/pgo-load:$(CO_BASEOS)-$(CO_VERSION)
rmdataimage:
	docker build -t pgo-rmdata -f $(CO_BASEOS)/Dockerfile.pgo-rmdata.$(CO_BASEOS) .
	docker tag pgo-rmdata crunchydata/pgo-rmdata:$(CO_BASEOS)-$(CO_VERSION)
all:
	make operatorimage
	make apiserverimage
	make lsimage
	make loadimage
	make pgo
	make rmdataimage
push:
	docker push crunchydata/pgo-lspvc:$(CO_IMAGE_TAG)
	docker push crunchydata/pgo-rmdata:$(CO_IMAGE_TAG)
	docker push crunchydata/pgo-load:$(CO_IMAGE_TAG)
	docker push crunchydata/postgres-operator:$(CO_IMAGE_TAG)
	docker push crunchydata/pgo-apiserver:$(CO_IMAGE_TAG)
release:	check-go-vars
	make macpgo
	rm -rf $(RELTMPDIR) $(RELFILE)
	mkdir $(RELTMPDIR)
	cp $(GOBIN)/pgo $(RELTMPDIR)
	cp $(GOBIN)/pgo-mac $(RELTMPDIR)
	cp $(COROOT)/examples/pgo-bash-completion $(RELTMPDIR)
	tar czvf $(RELFILE) -C $(RELTMPDIR) .
default:
	all

