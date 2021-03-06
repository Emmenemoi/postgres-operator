package main

import (
	"crypto/tls"
	"crypto/x509"
	log "github.com/Sirupsen/logrus"
	"github.com/crunchydata/postgres-operator/apiserver/backupservice"
	"github.com/crunchydata/postgres-operator/apiserver/cloneservice"
	"github.com/crunchydata/postgres-operator/apiserver/clusterservice"
	"github.com/crunchydata/postgres-operator/apiserver/labelservice"
	"github.com/crunchydata/postgres-operator/apiserver/loadservice"
	"github.com/crunchydata/postgres-operator/apiserver/policyservice"
	"github.com/crunchydata/postgres-operator/apiserver/pvcservice"
	"github.com/crunchydata/postgres-operator/apiserver/upgradeservice"
	"github.com/crunchydata/postgres-operator/apiserver/userservice"
	"github.com/crunchydata/postgres-operator/apiserver/versionservice"
	"github.com/gorilla/mux"
	"io/ioutil"
	"net/http"
	"os"
)

const serverCert = "/config/server.crt"
const serverKey = "/config/server.key"

func main() {

	debugFlag := os.Getenv("DEBUG")
	if debugFlag == "true" {
		log.SetLevel(log.DebugLevel)
		log.Debug("debug flag set to true")
	} else {
		log.Info("debug flag set to false")
	}

	log.Infoln("postgres-operator apiserver starts")
	r := mux.NewRouter()
	r.HandleFunc("/version", versionservice.VersionHandler)
	r.HandleFunc("/clones", cloneservice.CreateCloneHandler)
	r.HandleFunc("/policies", policyservice.CreatePolicyHandler)
	r.HandleFunc("/policies/{name}", policyservice.ShowPolicyHandler).Methods("GET", "DELETE")
	r.HandleFunc("/pvc/{pvcname}", pvcservice.ShowPVCHandler).Methods("GET")
	r.HandleFunc("/policies/apply", policyservice.ApplyPolicyHandler).Methods("POST")
	r.HandleFunc("/label", labelservice.LabelHandler).Methods("POST")
	r.HandleFunc("/load", loadservice.LoadHandler).Methods("POST")
	r.HandleFunc("/user", userservice.UserHandler).Methods("POST")
	r.HandleFunc("/upgrades", upgradeservice.CreateUpgradeHandler).Methods("POST")
	r.HandleFunc("/upgrades/{name}", upgradeservice.ShowUpgradeHandler).Methods("GET", "DELETE")
	r.HandleFunc("/clusters", clusterservice.CreateClusterHandler).Methods("POST")
	r.HandleFunc("/clusters/{name}", clusterservice.ShowClusterHandler).Methods("GET", "DELETE")
	r.HandleFunc("/clusters/test/{name}", clusterservice.TestClusterHandler)
	r.HandleFunc("/clusters/scale/{name}", clusterservice.ScaleClusterHandler)
	r.HandleFunc("/backups/{name}", backupservice.ShowBackupHandler).Methods("GET", "DELETE")
	r.HandleFunc("/backups", backupservice.CreateBackupHandler).Methods("POST")

	caCert, err := ioutil.ReadFile(serverCert)
	if err != nil {
		log.Fatal(err)
		log.Error("could not read " + serverCert)
		os.Exit(2)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)
	cfg := &tls.Config{
		//ClientAuth: tls.RequireAndVerifyClientCert,
		ClientCAs: caCertPool,
	}

	srv := &http.Server{
		Addr:      ":8443",
		Handler:   r,
		TLSConfig: cfg,
	}

	_, err = ioutil.ReadFile(serverKey)
	if err != nil {
		log.Fatal(err)
		log.Error("could not read " + serverKey)
		os.Exit(2)
	}

	log.Fatal(srv.ListenAndServeTLS(serverCert, serverKey))
	//log.Fatal(http.ListenAndServe(":8080", r))
}
