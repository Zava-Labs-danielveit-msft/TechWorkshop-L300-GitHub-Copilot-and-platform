using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure;
using Azure.AI.ContentSafety;
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
        private readonly ContentSafetyOptions _contentSafetyOptions;
        private readonly TokenCredential _credential;
        private readonly ContentSafetyClient _contentSafetyClient;
        private readonly ILogger<FoundryChatService> _logger;

        public FoundryChatService(
            HttpClient httpClient,
            IOptions<FoundryOptions> options,
            IOptions<ContentSafetyOptions> contentSafetyOptions,
            ILogger<FoundryChatService> logger)
        {
            _httpClient = httpClient;
            _options = options.Value;
            _contentSafetyOptions = contentSafetyOptions.Value;
            _logger = logger;
            _credential = new DefaultAzureCredential();

            if (string.IsNullOrWhiteSpace(_contentSafetyOptions.Endpoint))
            {
                throw new InvalidOperationException("Content Safety endpoint is not configured. Set ContentSafety:Endpoint in configuration.");
            }

            _contentSafetyClient = new ContentSafetyClient(new Uri(_contentSafetyOptions.Endpoint), _credential);
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

            var safetyDecision = await EvaluateContentSafetyAsync(message, cancellationToken);
            if (!safetyDecision.IsSafe)
            {
                return safetyDecision.WarningMessage;
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

        private async Task<(bool IsSafe, string WarningMessage)> EvaluateContentSafetyAsync(string message, CancellationToken cancellationToken)
        {
            var request = new AnalyzeTextOptions(message)
            {
                Categories =
                {
                    TextCategory.Violence,
                    TextCategory.Sexual,
                    TextCategory.Hate,
                    TextCategory.SelfHarm
                }
            };

            Response<AnalyzeTextResult> result = await _contentSafetyClient.AnalyzeTextAsync(request, cancellationToken);
            var jailbreakDetected = IsJailbreakAttempt(message);
            var isUnsafe = jailbreakDetected || result.Value.CategoriesAnalysis.Any(category => category.Severity >= 2);

            var categorySummary = string.Join(
                ", ",
                result.Value.CategoriesAnalysis.Select(category => $"{category.Category}:{category.Severity}"));

            _logger.LogInformation(
                "Content safety decision: {IsSafe}. Categories: {Categories}. Jailbreak: {Jailbreak}",
                !isUnsafe,
                categorySummary,
                jailbreakDetected);

            if (isUnsafe)
            {
                return (false, "I'm sorry, but I can't help with that request. Please try a different question.");
            }

            return (true, string.Empty);
        }

        private static bool IsJailbreakAttempt(string message)
        {
            var normalized = message.ToLowerInvariant();
            return normalized.Contains("ignore previous")
                || normalized.Contains("bypass")
                || normalized.Contains("system prompt")
                || normalized.Contains("jailbreak")
                || normalized.Contains("developer instructions");
        }
    }
}
