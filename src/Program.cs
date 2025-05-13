using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;
using Azure.Core;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Configure Azure Services
builder.Services.AddSingleton<AzureOpenAIClient>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var openAIEndpoint = configuration["AzureOpenAI:Endpoint"] ?? "https://sdellaliberaopenai.openai.azure.com/";
    var keyVaultUri = configuration["KeyVault:Uri"];
    
    if (!string.IsNullOrEmpty(keyVaultUri))
    {
        // In production, use managed identity to access Key Vault
        var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
        {
            AdditionallyAllowedTenants = { "72f988bf-86f1-41af-91ab-2d7cd011db47" }
        });
        
        var keyVaultClient = new SecretClient(new Uri(keyVaultUri), credential);
        var apiKey = keyVaultClient.GetSecret("AzureOpenAIKey").Value.Value;
        return new AzureOpenAIClient(new Uri(openAIEndpoint), new AzureKeyCredential(apiKey));
    }
    else
    {
        // Fallback for local development
        var apiKey = configuration["AzureOpenAI:ApiKey"];
        if (!string.IsNullOrEmpty(apiKey))
        {
            return new AzureOpenAIClient(new Uri(openAIEndpoint), new AzureKeyCredential(apiKey));
        }
        
        // Last resort - try managed identity directly
        return new AzureOpenAIClient(new Uri(openAIEndpoint), new DefaultAzureCredential());
    }
});

var app = builder.Build();

app.UseStaticFiles(); // Serve static files

app.MapGet("/", () => "Hello World!");

app.MapPost("/api/chat", async (ChatRequest request, AzureOpenAIClient azureClient) =>
{
    try 
    {
        ChatClient chatClient = azureClient.GetChatClient("gpt-4o-mini");
        ChatCompletion completion = await chatClient.CompleteChatAsync(
        [
            new SystemChatMessage("Sei un assistente virtuale che risponde a delle domande di vita quotidiana"),
            new UserChatMessage(request.Message),
        ]);
        
        return Results.Ok(new ChatResponse
        {
            Text = completion.Content[0].Text,
            Type = "bot"
        });
    }
    catch (Exception ex)
    {
        return Results.BadRequest(new ChatResponse
        {
            Text = "Sorry, I encountered an error processing your request.",
            Type = "bot"
        });
    }
});

app.Run();

public class ChatRequest
{
    public string Message {get; set;} = string.Empty;
}

public class ChatResponse
{
    public string Text {get; set;} = string.Empty;
    public string Type {get; set;} = string.Empty;
}