FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

COPY . .

RUN mvn -pl discovery-service -am clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

RUN apk add --no-cache wget

RUN addgroup -S pitaya && adduser -S pitaya -G pitaya

USER pitaya
WORKDIR /app

COPY --from=builder /build/discovery-service/target/*.jar app.jar

EXPOSE 8761

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8761/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]