FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

COPY . .

RUN mvn clean package -DskipTests -pl services/message-service -am

FROM eclipse-temurin:21-jre-alpine

RUN apk add --no-cache wget

RUN addgroup -S pitaya && adduser -S pitaya -G pitaya

USER pitaya

WORKDIR /app

COPY --from=builder /build/services/message-service/target/*.jar app.jar

EXPOSE 8089

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8089/actuator/health || exit 1

ENV JAVA_OPTS="-XX:+UseZGC -XX:ZCollectionInterval=30 -XX:ZFragmentationLimit=10 -Xlog:gc*:stdout:time"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]