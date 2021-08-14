package services

import (
	"context"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
)

type EC2Service struct {
	client *ec2.Client
}

func NewEC2Service() EC2Service {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	s := EC2Service{
		client: ec2.NewFromConfig(cfg),
	}
	return s
}

func (s EC2Service) GetName() string {
	return "Elastic Compute Cloud"
}

func (s EC2Service) RunCheck(check string) {
	switch check {
	case "instanceType":
		{
			s.RunInstanceTypeCheck()
		}
	default:
		{
			log.Print(check, "is not a valid check for EC2")
		}
	}
}
func (s EC2Service) RunAllChecks() {
	checks := s.GetChecks()
	for _, c := range checks {
		s.RunCheck(c)
	}
}
func (s EC2Service) GetChecks() []string {
	return []string{"instanceType"}
}

// RunInstanceTypeCheck deletes all EC2 instances that are not Free-Tier compliant.
func (s EC2Service) RunInstanceTypeCheck() {
	output, err := s.client.DescribeInstances(context.TODO(), &ec2.DescribeInstancesInput{
		//
	})
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Instance Listing:")
	for _, obj := range output.Reservations {
		for _, instance := range obj.Instances {
			log.Print("Instance ID: ", instance.InstanceType)
		}
	}
}
