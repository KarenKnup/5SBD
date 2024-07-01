using API.Data;
using API.Models;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure MySQL connection
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Call the data initialization method after app has started
app.Lifetime.ApplicationStarted.Register(() => Task.Run(async () => await InitializeDataAsync(app)).Wait());

app.Run();

async Task InitializeDataAsync(WebApplication app)
{
    using (var scope = app.Services.CreateScope())
    {
        var httpClient = new HttpClient();
        string produtosUrl = "https://localhost:7266/api/Produtos";
        string cargaTempUrl = "https://localhost:7266/api/CargaTemp";

        try
        {
            Console.WriteLine("Verificando se a API está respondendo...");

            // Verifica se a API está respondendo
            var produtosResponse = await httpClient.GetAsync(produtosUrl);
            produtosResponse.EnsureSuccessStatusCode();

            // Load and insert Produtos data
            Console.WriteLine("Carregando dados de Produtos...");
            var produtosJson = await System.IO.File.ReadAllTextAsync("produtos.json");
            var produtos = JsonConvert.DeserializeObject<List<Produtos>>(produtosJson);

            foreach (var produto in produtos)
            {
                var response = await httpClient.PostAsync(produtosUrl,
                    new StringContent(JsonConvert.SerializeObject(produto), Encoding.UTF8, "application/json"));

                if (response.IsSuccessStatusCode)
                {
                    Console.WriteLine($"Produto {produto.ProductName} inserido com sucesso.");
                }
                else
                {
                    Console.WriteLine($"Falha ao inserir o produto {produto.ProductName}: {response.ReasonPhrase}");
                }
            }

            // Verifica se a API está respondendo
            var cargaTempResponse = await httpClient.GetAsync(cargaTempUrl);
            cargaTempResponse.EnsureSuccessStatusCode();

            // Load and insert CargaTemp data
            Console.WriteLine("Carregando dados de CargaTemp...");
            var cargaTempJson = await System.IO.File.ReadAllTextAsync("cargatemp.json");
            var cargaTempList = JsonConvert.DeserializeObject<List<CargaTemp>>(cargaTempJson);

            foreach (var cargaTemp in cargaTempList)
            {
                var response = await httpClient.PostAsync(cargaTempUrl,
                    new StringContent(JsonConvert.SerializeObject(cargaTemp), Encoding.UTF8, "application/json"));

                if (response.IsSuccessStatusCode)
                {
                    Console.WriteLine($"CargaTemp com OrderId {cargaTemp.OrderId} inserido com sucesso.");
                }
                else
                {
                    Console.WriteLine($"Falha ao inserir a cargaTemp com OrderId {cargaTemp.OrderId}: {response.ReasonPhrase}");
                }
            }
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"Erro ao se comunicar com a API: {ex.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro inesperado: {ex.Message}");
        }
    }
}
