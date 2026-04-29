FROM dart:stable

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libsqlite3-0 libsqlite3-dev \
    tzdata \
  && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Seoul

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get

EXPOSE 8803

CMD ["dart", "run", "bin/server.dart"]
