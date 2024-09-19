FROM ghcr.io/gleam-lang/gleam:v1.4.1-erlang-alpine

# Install build dependencies
RUN apk add --no-cache gcc musl-dev make wget sqlite sqlite-dev

WORKDIR /build

COPY . /build

# Create DB
RUN chmod +x /build/create_db.sh
RUN /build/create_db.sh

# Compile the project
RUN cd /build \
    && gleam export erlang-shipment \
    && mv build/erlang-shipment /app \
    && rm -r /build

# Run the server
WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
