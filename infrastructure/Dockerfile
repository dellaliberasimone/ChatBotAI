FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["backend/chatbot-backend.csproj", "backend/"]
RUN dotnet restore "backend/chatbot-backend.csproj"
COPY . .
RUN dotnet build "backend/chatbot-backend.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "backend/chatbot-backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "chatbot-backend.dll"]