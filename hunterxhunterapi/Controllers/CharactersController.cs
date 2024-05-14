using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Hosting;
using Newtonsoft.Json;
using hunterxhunterapi.Models;
using System.IO;
using Microsoft.Extensions.Logging;

namespace hunterxhunterapi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CharactersController : ControllerBase
    {
        private readonly IWebHostEnvironment _hostingEnvironment;
        private readonly ILogger<CharactersController> _logger;

        public CharactersController(IWebHostEnvironment hostingEnvironment, ILogger<CharactersController> logger)
        {
            _hostingEnvironment = hostingEnvironment;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult GetAzureLocations()
        {
            try
            {
                // Log the request URL
                _logger.LogInformation($"Request received from {Request.Scheme}://{Request.Host}{Request.Path}{Request.QueryString}");

                // Assuming the JSON is stored in a file named "AzureLocations.json" in the wwwroot folder
                var jsonFilePath = Path.Combine(_hostingEnvironment.ContentRootPath, "hxhdata.json");

                // Read the JSON file
                var jsonData = System.IO.File.ReadAllText(jsonFilePath);

                // Deserialize the JSON to the C# object
                var CharactersList = JsonConvert.DeserializeObject<CharacterList>(jsonData);

                // Return the object as JSON in the API response
                return Ok(CharactersList.Characters);
            }
            catch (FileNotFoundException)
            {
                return NotFound("AzureLocations.json file not found.");
            }
            catch (JsonSerializationException)
            {
                return BadRequest("Error deserializing AzureLocations.json.");
            }
            catch (System.Exception)
            {
                return StatusCode(500, "An unexpected error occurred.");
            }
        }
    }
}
