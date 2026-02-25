namespace ZavaStorefront.Services
{
    public class FoundryOptions
    {
        public string Endpoint { get; set; } = string.Empty;
        public string PhiDeployment { get; set; } = "phi-4";
        public string ApiVersion { get; set; } = "2024-02-15-preview";
        public double Temperature { get; set; } = 0.7;
        public int MaxTokens { get; set; } = 200;
    }
}
