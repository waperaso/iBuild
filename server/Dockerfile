FROM dart:stable
WORKDIR /app
COPY server/pubspec.yaml server/pubspec.lock ./
RUN dart pub get
COPY server/ ./
RUN dart pub get
ENV MIGRATIONS_DIR=/app/migrations
ENV WEB_ROOT=/app/web
ENV PORT=8080
ENV HOST=0.0.0.0
EXPOSE 8080
CMD ["dart", "run", "bin/server.dart"]
