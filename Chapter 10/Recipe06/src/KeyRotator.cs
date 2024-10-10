using System;
using System.Linq;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.AppService;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.AppService.Models;
using Azure.ResourceManager.CognitiveServices;
using Azure.ResourceManager.CognitiveServices.Models;

namespace src
{
    public class KeyRotator
    {
        private readonly IConfiguration _configuration;
        private readonly ResourcesConfig _resourceConfig;
        private readonly AuthConfig _authConfig;

        public KeyRotator(IConfiguration configuration)
        {
            _configuration = configuration;
            _resourceConfig = new ResourcesConfig();
            _resourceConfig.Load(_configuration);
            _authConfig = new AuthConfig();
            _authConfig.Load(_configuration);
        }

        [FunctionName("KeyRotator")]
        public async Task Run([TimerTrigger("%RotationTimer%")] TimerInfo myTimer,
            ILogger log)
        {

            log.LogInformation($"KeyRotator executed at: {DateTime.Now}");

            // Create the AzureCredential instance using ClientId,ClientSecret and 
            var credentials = new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityClientId = _authConfig.ManagedIdentityId });
            
            // Create the ARM Client instance using the credentials
            ArmClient client = new ArmClient(credentials);
            
            // Retrieve the subscription contains Cognitive Service and App Service
            var subId = new ResourceIdentifier(_resourceConfig.GetSubscriptionResourceId());
            var subscription = client.GetSubscriptions().FirstOrDefault(s => s.Id == subId);

            // Retrieve the resource group contains Cognitive Service and App Service
            ResourceGroupResource resourceGroup = await subscription.GetResourceGroupAsync(_resourceConfig.ResourceGroupName);

            // Retrieve the App Service and Cognitive Service           
            CognitiveServicesAccountResource cognitive = await resourceGroup.GetCognitiveServicesAccountAsync(_resourceConfig.CognitiveServiceName);
            ServiceAccountApiKeys cognitiveKeys = await cognitive.GetKeysAsync(default);

            WebSiteResource appservice = await resourceGroup.GetWebSiteAsync(_resourceConfig.AppServiceName);
            AppServiceConfigurationDictionary appSettings = await appservice.GetApplicationSettingsAsync(default);

            // Check if the App Service configuration contains the setting with the key name
            if (appSettings.Properties.TryGetValue(_resourceConfig.CognitiveKeySettingName,
                out var cognitiveKeySetting))
            {
                ServiceAccountKeyName keyNameToRotate;
                string newKey = null;
                // Check if the App Service is using the Key1 or the Key2
                if (cognitiveKeySetting == cognitiveKeys.Key1)
                {
                    keyNameToRotate = ServiceAccountKeyName.Key1;
                    newKey = cognitiveKeys.Key2;
                }
                else
                {
                    keyNameToRotate = ServiceAccountKeyName.Key2;
                    newKey = cognitiveKeys.Key1;
                }

                log.LogInformation($"Key to rotate: {keyNameToRotate}");
                
                // Update the App Service configuration with the new key
                appSettings.Properties[_resourceConfig.CognitiveKeySettingName] = newKey;
                await appservice.UpdateApplicationSettingsAsync(appSettings, default);

                // Regenerate the key in Cognitive Service
                var content = new RegenerateServiceAccountKeyContent(keyNameToRotate);
                ServiceAccountApiKeys rotatedKeys=await cognitive.RegenerateKeyAsync(content, default);
            }
        }
    }
}
