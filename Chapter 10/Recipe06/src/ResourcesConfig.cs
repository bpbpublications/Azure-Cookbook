using Microsoft.Extensions.Configuration;

namespace src
{
    internal class ResourcesConfig
    {
        public string SubscriptionId { get; set; }
        public string CognitiveKeySettingName { get; set; }
        public string CognitiveServiceName { get; set; }
        public string AppServiceName { get; set; }
        public string ResourceGroupName { get; set; }

        public string GetSubscriptionResourceId()
        {
            return $"/subscriptions/{SubscriptionId}";
        }

        public void Load(IConfiguration configuration)
        {
            this.SubscriptionId = configuration["SubscriptionId"];
            this.CognitiveKeySettingName = configuration["CognitiveKeySettingName"];
            this.CognitiveServiceName = configuration["CognitiveServiceName"];
            this.AppServiceName = configuration["AppServiceName"];
            this.ResourceGroupName = configuration["ResourceGroupName"];
        }
    }
}
