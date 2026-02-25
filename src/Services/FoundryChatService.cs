using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Options;

namespace ZavaStorefront.Services
{
    public class FoundryChatService
    {
        private static readonly string[] TokenScopes = new[] { "https://cognitiveservices.azure.com/.default" };
        private readonly HttpClient _httpClient;
        private readonly FoundryOptions _options;
        private readonly TokenCredential _credential;

        public FoundryChatService(HttpClient httpClient, IOptions<FoundryOptions> options)
        {
            _httpClient = httpClient;
            _options = options.Value;
            _credential = new DefaultAzureCredential();
        }

        public async Task<string> SendMessageAsync(string message, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(_options.Endpoint))
            {
                throw new InvalidOperationException("Foundry endpoint is not configured. Set Foundry:Endpoint in configuration.");
            }

            if (string.IsNullOrWhiteSpace(_options.PhiDeployment))
            {
                throw new InvalidOperationException("Foundry deployment is not configured. Set Foundry:PhiDeployment in configuration.");
            }

            var token = await _credential.GetTokenAsync(new TokenRequestContext(TokenScopes), cancellationToken);
            var requestUri = BuildChatCompletionsUri();

            using var request = new HttpRequestMessage(HttpMethod.Post, requestUri);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
            request.Content = new StringContent(BuildRequestBody(message), Encoding.UTF8, "application/json");

            using var response = await _httpClient.SendAsync(request, cancellationToken);
            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException($"Foundry request failed: {(int)response.StatusCode} {response.ReasonPhrase}. {responseBody}");
            }

            return ExtractAssistantMessage(responseBody);
        }

        private Uri BuildChatCompletionsUri()
        {
            var baseUri = _options.Endpoint.TrimEnd('/');
            var deployment = Uri.EscapeDataString(_options.PhiDeployment);
            var apiVersion = Uri.EscapeDataString(_options.ApiVersion);

            return new Uri($"{baseUri}/openai/deployments/{deployment}/chat/completions?api-version={apiVersion}");
        }

        private string BuildRequestBody(string message)
        {
            var payload = new
            {
                messages = new[]
                {
                    new { role = "user", content = message }
                },
                temperature = _options.Temperature,
                max_tokens = _options.MaxTokens
            };

            return JsonSerializer.Serialize(payload);
        }

        private static string ExtractAssistantMessage(string responseBody)
        {
            using var document = JsonDocument.Parse(responseBody);

            if (!document.RootElement.TryGetProperty("choices", out var choices) || choices.GetArrayLength() == 0)
            {
                return string.Empty;
            }

            var message = choices[0].GetProperty("message");
            return message.GetProperty("content").GetString() ?? string.Empty;
        }
    }
}
