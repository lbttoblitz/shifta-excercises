using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text;

namespace API_3.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class FilesController : ControllerBase
	{
		[HttpPost]
		public async Task<IActionResult> Receiver_3()
		{
			var path = Path.Combine("/app/data", $"shared-value.txt");
			System.IO.File.AppendAllText(path, $"{Environment.NewLine} Información recibida de api 1 y 2, enviando información de respuesta.... {Environment.NewLine} INFORMACION DE RESPUESTA");
			var response = await System.IO.File.ReadAllTextAsync(path);
			return Ok(response);
		}
	}
}
