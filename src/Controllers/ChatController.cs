using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly FoundryChatService _chatService;
        private readonly ILogger<ChatController> _logger;

        public ChatController(FoundryChatService chatService, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Send([FromBody] ChatRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Message))
            {
                return BadRequest(new { error = "Message is required." });
            }

            try
            {
                var reply = await _chatService.SendMessageAsync(request.Message, HttpContext.RequestAborted);
                return Json(new { reply });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Foundry chat request failed");
                return StatusCode(StatusCodes.Status502BadGateway, new { error = "Chat request failed." });
            }
        }
    }
}
