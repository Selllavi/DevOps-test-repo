##
## Build stage, compile all resources
##
FROM 723915311050.dkr.ecr.eu-west-1.amazonaws.com/golang:1.16-buster AS build

WORKDIR /weather

COPY *.go ./
COPY static ./static
COPY go.mod ./

RUN go mod download
RUN go build -o /weather/docker-weather
RUN go test ./...

RUN useradd nonroot
RUN chown -R nonroot /weather

##
## Deploy stage pick up compiled resources from previous stage
## to minimize container size and increase security
##

FROM 723915311050.dkr.ecr.eu-west-1.amazonaws.com/base-debian10:1.0

WORKDIR /weather

COPY --from=build /weather .

## Do not use root user for security reason
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT [ "./docker-weather" ]