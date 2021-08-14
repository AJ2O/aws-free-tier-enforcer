package services

type ServiceInterface interface {
	// GetName Todo
	GetName() string
	// RunCheck TODO
	RunCheck(check string)
	// RunAllChecks TODO
	RunAllChecks()
	// GetChecks TODO
	GetChecks() []string
}
