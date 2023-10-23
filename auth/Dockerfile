FROM rust

ENV ROCKET_PORT=80

WORKDIR /app
COPY . .

RUN rustup default nightly
RUN cargo build

HEALTHCHECK --interval=10s CMD curl localhost/login

CMD ["cargo", "run"]