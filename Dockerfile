FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

ARG TARGETPLATFORM

RUN case "${TARGETPLATFORM:-$(uname -m)}" in \
    "linux/amd64"|"x86_64") RID="linux-musl-x64" ;; \
    "linux/arm64"|"aarch64") RID="linux-musl-arm64" ;; \
    "linux/arm/v7"|"armv7l") RID="linux-musl-arm" ;; \
    *) echo "Unsupported platform: ${TARGETPLATFORM:-$(uname -m)}" >&2; exit 1 ;; \
    esac \
    && printf 'RID=%s\n' "$RID" > /tmp/rid.txt

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
RUN . /tmp/rid.txt && dotnet publish Scratch/Scratch.csproj \
    -c Release \
    -r "$RID" \
    -o /app/publish \
    -p:PublishAot=true \
    -p:StaticExecutable=true \
    -p:StaticIcuLinking=true \
    -p:StaticOpenSslLinking=true \
    -p:StaticNumaLinking=true

FROM scratch AS final

COPY --from=build /app/publish/Scratch /Scratch
ENTRYPOINT ["/Scratch"]
