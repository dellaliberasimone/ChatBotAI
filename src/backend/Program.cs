using ServiceDefaults;
using OpenAI;
using Microsoft.Extensions.Diagnostics.Enrichment;
using OpenAI.Chat;
using ChatClasses;
using System;


var MyAllowSpecificOrigins = "_MyAllowSpecificOrigins";

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

var frontendEndpoint = Environment.GetEnvironmentVariable("services__react__endpoint__0");

builder.AddAzureOpenAIClient(connectionName: "azureOpenAI");

builder.AddAzureSearchClient(connectionName:"search");

builder.Services.AddCors(option =>
{
    option.AddPolicy(name: MyAllowSpecificOrigins,
        policy =>
        {
            // Allow the frontend endpoint from Aspire environment variable
            if (!string.IsNullOrEmpty(frontendEndpoint))
            {
                policy.WithOrigins(frontendEndpoint);
            }
            
            // Also allow common development URLs
            policy.AllowAnyHeader().AllowAnyMethod();
        });
});

var app = builder.Build();

app.MapDefaultEndpoints();

app.UseCors(MyAllowSpecificOrigins);

app.UseStaticFiles();

// Basic health check endpoint
app.MapGet("/", () => "Hello World! Backend API is running.");

app.MapPost("/api/chat", async (ChatRequest request,OpenAIClient AIClient) =>
{
    try
    {
        var chatClient = AIClient.GetChatClient("gpt-4o-mini");
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
        Console.WriteLine($"Exception: {ex.Message}");
        Console.WriteLine($"Stack trace: {ex.StackTrace}");
        if (ex.InnerException != null)
            Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
        
        return Results.BadRequest(new ChatResponse
        {
            Text = "Mi dispiace, ho incontrato un errore durante la tua richiesta.",
            Type = "bot"
        });
    }
});


app.Run();

