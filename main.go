package main

import (
	"log"
	"net/http"
	"time"

	svc "github.com/AJ2O/free-tier-enforcer/services"
	"github.com/gorilla/mux"
)

func main() {
	// TODO: parse arguments
	waitTimeSeconds := time.Second * 300

	// allocate service connections
	services := []svc.ServiceInterface{}
	services = append(services, svc.NewEC2Service())

	// initialize http router
	r := mux.NewRouter()

	// start web server in the background
	go func() {
		log.Fatal(http.ListenAndServe(":80", r))
	}()

	// run service checks forever
	startTime := time.Now()
	log.Print("Started at ", startTime.Format(time.RFC3339))
	for {
		for _, s := range services {
			log.Print("Running checks for ", s.GetName())
			s.RunAllChecks()
		}
		time.Sleep(waitTimeSeconds)
	}
}
