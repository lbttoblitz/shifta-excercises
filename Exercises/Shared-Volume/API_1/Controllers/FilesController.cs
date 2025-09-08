using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.IO;
using System.Text;
namespace API_1.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class FilesController : ControllerBase
	{
		[HttpPost]
		public async Task<IActionResult> Sender_1()
		{
			var path = Path.Combine("/app/data", $"shared-value.txt");
			await System.IO.File.WriteAllTextAsync(path, $"enviando información a API_2....");
			
			using (var client = new HttpClient())
			{
				var responseMessage = await client.PostAsync("http://api_2:80/api/Files", null);
				var responseBody = await responseMessage.Content.ReadAsStringAsync();
				return Ok(responseBody);
			}
		}
	}
}
