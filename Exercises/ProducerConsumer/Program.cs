
using System.Diagnostics;

namespace ProducerConsumer;

public class Program
{
    private static readonly Queue<MessageDto> _queue = new Queue<MessageDto>();
    private static readonly object _lock = new object();
    private static SemaphoreSlim? _itemsAvailable; // Controla cuántos elementos hay en la cola
    private static SemaphoreSlim? _queueSpaceAvailable; // Controla cuántos espacios quedan
    private static int _prodCount = 0;
    private static int _consCount = 0;
    private static int _maxQueueSize = 0;
    private static int _timeToSleep = new Random().Next(200, 1200);
    private static CancellationTokenSource _cts = new CancellationTokenSource();
    private static string _rootDirectory => $"{AppDomain.CurrentDomain.BaseDirectory}_info.txt";

    static async Task Main(string[] args)
    {
        if (File.Exists(_rootDirectory))
            File.Delete(_rootDirectory);

        await WriteLine("Number of producers: ", addNewLine : false);
        if (!int.TryParse(Console.ReadLine(), out int prodCount))
        {
            await WriteLine("Error in the number of assigned producers");
            return;
        }

        await WriteLine("Number of consumers: ", addNewLine: false);
        if (!int.TryParse(Console.ReadLine(), out int consCount))
        {
            await WriteLine("Error en la cantidad de consumidores asignados");
            return;
        }

        await WriteLine("Number of messages in queue: ", addNewLine: false);
        if (!int.TryParse(Console.ReadLine(), out int maxQueueSize))
        {
            await WriteLine("Error in the number of messages allocated in the queue");
            return;
        }

        _prodCount = prodCount;
        _consCount = consCount;
        _maxQueueSize = maxQueueSize;
        _itemsAvailable = new SemaphoreSlim(0); // No hay mensajes al inicio
        _queueSpaceAvailable = new SemaphoreSlim(_maxQueueSize); // La cola tiene espacio para maxQueueSize mensajes

        var _producerTasks = new Task[_prodCount];
        var _consumerTasks = new Task[_consCount];

        for (int i = 0; i < _consCount; i++)
        {
            int consumerId = i;
            _consumerTasks[i] = Task.Run(()=> Consumer (consumerId, _cts.Token));
        }

        for (int i = 0; i < _prodCount; i++)
        {
            int producerId = i;
            _producerTasks[i] = Task.Run(() => Producer(producerId, _cts.Token));
        }

        await WriteLine("Press any key to exit...");
        Console.ReadKey();
        _cts.Cancel();

        var allTasks = _consumerTasks.Concat(_producerTasks);
        await Task.WhenAll(allTasks);
    }


    private static async Task Consumer(object? state, CancellationToken cancellationToken)
    {
        var consumerName = (int)state;
        await WriteLine($"Starting Consumer {consumerName}");
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                await WriteLine($"[Consumer:{consumerName}] is waiting for queue message");
                await _itemsAvailable!.WaitAsync(); // Espera hasta que haya un mensaje en la cola

                MessageDto? message = null;
                lock (_lock)
                {
                    if (_queue.Count > 0)
                        message = _queue.Dequeue();
                }

                if (message != null)
                {
                    await WriteLine($"[Consumer:{consumerName}] receiving message with id: {message.Id}");
                    _queueSpaceAvailable?.Release(); // Libera un espacio en la cola
                }

                await Task.Delay(_timeToSleep, cancellationToken);
            }
            catch (OperationCanceledException)
            {
                await WriteLine($"[Consumer:{consumerName}] stopped.");
                break;
            }
        }
    }
    private static async Task Producer(object? state, CancellationToken cancellationToken)
    {
        var producerName = (int)state;  
        await WriteLine($"Starting Producer {(int)state}");
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                await WriteLine($"[Producer:{producerName}] is waiting for queue space");
                await _queueSpaceAvailable!.WaitAsync(cancellationToken); // Espera hasta que haya un espacio libre en la cola

                MessageDto? message = null;
                lock (_lock)
                {
                    message = new MessageDto
                    {
                        Id = $"{Environment.MachineName}:{Process.GetCurrentProcess().Id}:{producerName}",
                    };

                    _queue.Enqueue(message);
                }

                await WriteLine($"[Producer:{producerName}] Send message with id: {message.Id}");
                _itemsAvailable?.Release(); // Notifica que hay un nuevo mensaje disponible
                await Task.Delay(_timeToSleep, cancellationToken);
            }
            catch (OperationCanceledException)
            {
                await WriteLine($"[Producer:{producerName}] stopped.");
                break;
            }
        }
    }

    private async static Task WriteLine(string desc, bool addNewLine = true)
    {
        if (addNewLine)
            Console.WriteLine(desc);
        else
            Console.Write(desc);
        
        using (var stream = new FileStream(_rootDirectory, FileMode.Append, FileAccess.Write, FileShare.ReadWrite))
        using (var writer = new StreamWriter(stream))
        {
            if(addNewLine)
                await writer.WriteLineAsync(desc);
            else
                await writer.WriteAsync(desc);
        }
    }
}
    class MessageDto
    {
        public string Id { get; set; } = string.Empty;
    }
