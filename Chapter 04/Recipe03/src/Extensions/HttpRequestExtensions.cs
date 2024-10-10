namespace Microsoft.AspNetCore.Mvc
{
    public static class HttpRequestExtensions
    {

        public static IDictionary<string, string> GetHeaders(this HttpRequest request)
        {
            var dict = new Dictionary<string, string>();
            foreach (var header in request.Headers)
            {
                dict.Add(header.Key, header.Value);
            }
            return dict;
        }
      
    }
}
