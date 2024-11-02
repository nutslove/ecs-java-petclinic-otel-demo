FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
COPY aws-opentelemetry-agent.jar ./

RUN chmod +x mvnw && ./mvnw dependency:resolve

COPY src ./src

ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=otlp
ENV OTEL_LOGS_EXPORTER=otlp
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
ENV OTEL_SERVICE_NAME=spring-petclinic
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=spring-petclinic,service.namespace=ecs
ENV JAVA_TOOL_OPTIONS="-javaagent:/app/aws-opentelemetry-agent.jar"

CMD ["./mvnw", "spring-boot:run"]
