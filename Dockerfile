# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# Use multi-arch base images
FROM --platform=$TARGETPLATFORM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["swagger-minimal-api.csproj", "."]
RUN dotnet restore "swagger-minimal-api.csproj"
COPY . .
RUN dotnet build "swagger-minimal-api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "swagger-minimal-api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "swagger-minimal-api.dll"]