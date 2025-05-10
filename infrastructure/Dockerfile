FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/swagger-minimal-api.csproj", "src/"]
RUN dotnet restore "src/swagger-minimal-api.csproj"
COPY . .
RUN dotnet build "src/swagger-minimal-api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "src/swagger-minimal-api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "swagger-minimal-api.dll"]