using Microsoft.Extensions.Configuration;

namespace src
{
    internal class AuthConfig
    {
        public string ManagedIdentityId { get; set; }

        public void Load(IConfiguration configuration)
        {
            this.ManagedIdentityId = configuration["ManagedIdentityId"];
        }
    }
}
