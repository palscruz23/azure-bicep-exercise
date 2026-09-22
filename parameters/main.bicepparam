using '../main.bicep'

// Change this to a short, globally distinctive prefix before deployment.
param namePrefix = 'iacpractice'

param tags = {
  environment: 'practice'
  managedBy: 'bicep'
  project: 'azure-iac-learning'
}

// Set to true when you are ready to practise optional monitoring resources.
param deployLogAnalytics = false

// These resources cost money. Enable one at a time while practising.
param deployContainerRegistry = false
param deployContainerApp = false
param deployPostgres = false
