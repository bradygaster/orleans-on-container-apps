param appName string
param location string
param containerAppEnvironmentId string
param envVars array = []
param minReplicas int = 1
param maxReplicas int = 10
param repositoryImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param registry string
param registryUsername string
@secure()
param registryPassword string

resource scalerContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      secrets: [
        {
          name: 'container-registry-password'
          value: registryPassword
        }
      ]
      registries: [
        {
          server: registry
          username: registryUsername
          passwordSecretRef: 'container-registry-password'
        }
      ]
      ingress: {
        external: false
        targetPort: 80
        allowInsecure: true
        transport: 'http2'
      }
    }
    template: {
      containers: [
        {
          image: repositoryImage
          name: appName
          env: envVars
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'multiple'
      secrets: [
        {
          name: 'container-registry-password'
          value: registryPassword
        }
      ]
      registries: [
        {
          server: registry
          username: registryUsername
          passwordSecretRef: 'container-registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: repositoryImage
          name: appName
          env: envVars
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'scaler'
            custom: {
              type: 'external'
              metadata: {
                scalerAddress: '${scalerContainerApp.properties.configuration.ingress.fqdn}:80'
                graintype: 'sensortwin'
                siloNameFilter: 'silo'
                upperbound: '300'
              }
            }
          }
        ]
      }
    }
  }
}
