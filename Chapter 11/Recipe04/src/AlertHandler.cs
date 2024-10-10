using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace src
{
    public static class AlertHandler
    {
        [FunctionName("AlertHandler")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // Parse the request body
            string requestBody=null;
            using (StreamReader reader = new StreamReader(req.Body))
            {
                requestBody= await reader.ReadToEndAsync();
            }
            JObject parsedJson = JObject.Parse(requestBody);

            // Extract AlertId
            string alertId = parsedJson["data"]["essentials"]["alertId"].Value<string>();
            log.LogInformation($"AlertId: {alertId}");

            // Extract operation Name
            string operationName = parsedJson["data"]["alertContext"]["operationName"].Value<string>();
            log.LogInformation($"OperationName: {operationName}");

            // Extract customProperties
            JObject customProperties = parsedJson["data"]["customProperties"] as JObject;     
            foreach (var property in customProperties)
            {
                log.LogInformation($"Custom Property: {property.Key} = {property.Value}");
            }

            return new OkResult();
        }
    }
}
