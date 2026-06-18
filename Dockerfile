FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

RUN apk add --no-cache \
    clang \
    build-base \
    cmake \
    icu-dev \
    openssl-dev \
    zlib-static \
    icu-static \
    openssl-libs-static

COPY Scratch/Scratch.csproj Scratch/
RUN dotnet restore Scratch/Scratch.csproj

COPY Scratch/ Scratch/
RUN dotnet publish Scratch/Scratch.csproj \
    -c Release \
    -r linux-musl-x64 \
    -o /app/publish \
    -p:PublishAot=true \
    -p:StaticExecutable=true \
    -p:StaticIcuLinking=true \
    -p:StaticOpenSslLinking=true \
    -p:StaticNumaLinking=true

FROM scratch AS final

COPY --from=build /app/publish/Scratch /Scratch
ENTRYPOINT ["/Scratch"]
