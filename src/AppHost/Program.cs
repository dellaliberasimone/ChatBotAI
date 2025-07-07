var builder = DistributedApplication.CreateBuilder(args);

//configure openai endpoint
var openAI = builder.AddConnectionString("azureOpenAI");
//var openAI = builder.AddAzureOpenAI("azureOpenAI");

//configure backend project
var backend = builder.AddProject<Projects.chatbotAPI>("chatbotAPI")
                .WithReference(openAI);

var frontend = builder.AddNpmApp("react", "../frontend")
                .WithEnvironment("REACT_APP_API_URL", backend.GetEndpoint("https"))
                .WithHttpEndpoint(name: "endpoint", env: "PORT");

var endpoint = frontend.GetEndpoint("endpoint");

backend.WithReference(endpoint);


builder.Build().Run();
