FROM dart:stable AS build

WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates libsqlite3-0 && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/bin/server

RUN mkdir -p /app/data

EXPOSE 8080

CMD ["/app/bin/server"]
