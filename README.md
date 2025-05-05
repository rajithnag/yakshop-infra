# Yakshop Infrastructure

This project contains the Bicep templates and modules required to deploy the Azure infrastructure for the Yakshop website. The infrastructure is designed to support a website written in Node.js and business logic/APIs written in C# on .NET Core. The backend is deployed as microservices to effectively managed and scale.

## Project Structure

The project is organized as follows:

- **bicep/**: Contains all Bicep templates and modules for resource deployment.
  - **main.bicep**: The main entry point for the Bicep deployment, orchestrating the deployment of all resources.
  - **modules/**: Contains individual Bicep modules for each resource.
    - **network.bicep**: Defines the virtual network (VNet) with appSubnet, databaseSubnet and gatewaySubnet.
    - **apim.bicep**: Sets up the Azure API Management (APIM) service and Application Gateway with SSL and WAF in gatewaySubnet.
    - **appServicePlan.bicep**: Creates an App Service Plan in the appSubnet.
    - **webAppFrontend.bicep**: Deploys the frontend web application (Node.js).
    - **webAppBackend.bicep**: Deploys the backend web application (C# on .NET Core).
    - **functionApp.bicep**: Creates an Azure Function App for additional backend tasks.
    - **serviceBus.bicep**: Provisions an Azure Service Bus Queue.
    - **sqlDatabase.bicep**: Sets up an Azure SQL Database in the databaseSubnet.
    - **storage.bicep**: Provisions Azure Blob Storage.
    - **keyVault.bicep**: Creates an Azure Key Vault for secrets management.
    - **appInsights.bicep**: Sets up Azure Application Insights for monitoring.
    - **managed-identities/**: These user assigned managed identities will be assigned to respective azure resources to grant access to other required azure resources such as keyVault etc. If a perticular resource need access to any other azure resource, we can extend these files.
    - **monitoring-alerts.bicep**: Azure Monitor alert rules for critical metrics (CPU, memory, HTTP errors, etc.)

- **parameters/**: Contains parameter files for different environments (dev, test, acc, prod). Currently not used much but in production scenario we will need them to manage specific azure configurations as well as application configurations.
  - **dev.parameters.json**: Parameter values for the development environment.
  - **test.parameters.json**: Parameter values for the testing environment.
  - **acc.parameters.json**: Parameter values for the acceptance environment.
  - **prod.parameters.json**: Parameter values for the production environment.

## Deploy Using Azure Devops pipeline
Parameter files should be located in bicep/parameters/ with names matching the environments (e.g., dev.parameters.json, test.parameters.json).

## Usage

After deployment, you can access the frontend and backend applications via the configured API Management service. Monitor application performance and logs using Azure Application Insights.

For further customization and resource management, refer to the individual Bicep module files in the `bicep/modules/` directory.
