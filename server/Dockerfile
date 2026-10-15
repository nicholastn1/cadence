FROM golang:1.23-alpine AS build
WORKDIR /src
COPY . .
RUN go test ./... && CGO_ENABLED=0 go build -o /cadence-server .

FROM gcr.io/distroless/static-debian12
COPY --from=build /cadence-server /cadence-server
ENV DATA_DIR=/data PORT=8080
EXPOSE 8080
ENTRYPOINT ["/cadence-server"]
