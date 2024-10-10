// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using Azure.Identity;
using Azure.Storage.Blobs;
using System.Threading.Tasks;

namespace src
{
    public class BlobRecover
    {
        private readonly IConfiguration configuration;

        public BlobRecover(IConfiguration configuration)
        {
            this.configuration = configuration;
        }

        [FunctionName("BlobRecover")]
        public async Task Run([EventGridTrigger] EventGridEvent eventGridEvent, ILogger log)
        {
            log.LogInformation(eventGridEvent.Data.ToString());
            var data = JsonSerializer.Deserialize<BlobDeletedData>(eventGridEvent.Data.ToString(), 
                new JsonSerializerOptions()
                    {
                        PropertyNameCaseInsensitive = true
                    }
            );

            var credential = new ManagedIdentityCredential();
            var blobClient = new BlobClient(new Uri(data.url), credential);

            try
            {
                var undeleteResponse = await blobClient.UndeleteAsync();
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Error undeleting blob {data.url}");
            }
        }
    }
}
