FROM golang:1.20-alpine AS build
WORKDIR /app
COPY . .
RUN go build -o server ./

FROM alpine:3.18
COPY --from=build /app/server /usr/local/bin/server
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/server"]
