# Stage 1: Build and Publish
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy the csproj and restore dependencies
COPY ["BlobWorker.csproj", "./"]
RUN dotnet restore "BlobWorker.csproj"

# Copy the rest of the code and publish
COPY . .
RUN dotnet publish "BlobWorker.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Run
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app

# Copy the published output from the build stage
COPY --from=build /app/publish .

# Run the worker service
ENTRYPOINT ["dotnet", "BlobWorker.dll"]