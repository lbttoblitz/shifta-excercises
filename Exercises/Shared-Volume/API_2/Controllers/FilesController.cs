using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text;

namespace API_2.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class FilesController : ControllerBase
	{
		[HttpPost]
		public async Task<IActionResult> Receiver_2()
		{
			var path = Path.Combine("/app/data", $"shared-value.txt");
			System.IO.File.AppendAllText(path, $"{Environment.NewLine} Informacion recibida de Api 1, enviando información a API_3....");

			using (var client = new HttpClient())
			{
				var responseMessage = await client.PostAsync("http://api_3:80/api/Files", null);
				var responseBody = await responseMessage.Content.ReadAsStringAsync();
				return Ok(responseBody);
			}
		}
	}
}
