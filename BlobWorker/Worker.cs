using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using System.Text.Json;

namespace BlobWorker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly ServiceBusProcessor _processor;

        public Worker(ILogger<Worker> logger, IConfiguration configuration)
        {
            _logger = logger;

            var fullyQualifiedNamespace = configuration["ServiceBusNamespace"]; // e.g., "sb-event-demo-123.servicebus.windows.net"
            var queueName = configuration["QueueName"];

            var client = new ServiceBusClient(fullyQualifiedNamespace, new DefaultAzureCredential());
            _processor = client.CreateProcessor(queueName, new ServiceBusProcessorOptions());
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _processor.ProcessMessageAsync += MessageHandler;
            _processor.ProcessErrorAsync += ErrorHandler;

            await _processor.StartProcessingAsync(stoppingToken);

            // Keep running until stopped
            await Task.Delay(Timeout.Infinite, stoppingToken);

            await _processor.StopProcessingAsync();
        }

        private async Task MessageHandler(ProcessMessageEventArgs args)
        {
            string body = args.Message.Body.ToString();
            _logger.LogInformation($"Received message: {body}");

            using JsonDocument doc = JsonDocument.Parse(body);
            JsonElement root = doc.RootElement;

            // Event Grid wraps the data inside a standard schema array or object
            if (root.TryGetProperty("data", out JsonElement dataElement) && 
                dataElement.TryGetProperty("url", out JsonElement urlElement))
            {
                string blobUrl = urlElement.GetString();
                _logger.LogInformation($"Extracted Blob URL: {blobUrl}");

                // Download and read the blob content
                var blobClient = new BlobClient(new Uri(blobUrl), new DefaultAzureCredential());
                var content = await blobClient.DownloadContentAsync();
                
                _logger.LogInformation($"Blob Content read successfully: {content.Value.Content}");

                // Delete the blob after reading
                await blobClient.DeleteAsync();
                _logger.LogInformation($"Blob deleted successfully: {blobUrl}");
            }

            await args.CompleteMessageAsync(args.Message);
        }

        private Task ErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError(args.Exception, "Message handler encountered an exception");
            return Task.CompletedTask;
        }
    }
}