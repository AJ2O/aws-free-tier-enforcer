module github.com/AJ2O/free-tier-enforcer

go 1.16

require (
	github.com/AJ2O/free-tier-enforcer/services v0.0.0-00010101000000-000000000000 // indirect
	github.com/aws/aws-sdk-go-v2/config v1.6.0
	github.com/aws/aws-sdk-go-v2/service/ec2 v1.13.0
	github.com/gorilla/mux v1.8.0 // indirect
)

replace github.com/AJ2O/free-tier-enforcer/services => ./src/services
