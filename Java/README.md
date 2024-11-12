# Fork
- 以下リポジトリからFork
  - https://github.com/spring-projects/spring-petclinic

# 事前準備
- ビルドするサーバにてDockerとDocker Composeをインストール
- ECSのTaskの`logConfiguration`で送るログの送り先のCloudWatch LogsのLogGroupを作成
- 以下URLから最新の`aws-opentelemetry-agent.jar`をダウンロード
  - https://github.com/aws-observability/aws-otel-java-instrumentation/releases
- ADOT CollectorのConfigファイルを作成
- `aws-opentelemetry-agent.jar`とADOT CollectorのConfigファイルをEFS経由でECSのTaskから読み込めるところに配置しておく

# 加えた変更
### `pom.xml`
- `./pom.xml`に以下を追加  
  ```xml
  <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-registry-prometheus</artifactId>
  </dependency>

  <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-tracing-bridge-otel</artifactId>
  </dependency>

  <dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-logback-mdc-1.0</artifactId>
    <version>2.9.0-alpha</version>
  </dependency>

  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
  </dependency>

  <dependency>
      <groupId>software.amazon.opentelemetry</groupId>
      <artifactId>aws-opentelemetry-agent</artifactId>
      <version>1.32.5</version>
  </dependency>
  ```

### `application.properties`
- `./src/main/resources/application.properties`に以下を追加  
  ```
  management.endpoints.web.exposure.include=*
  management.endpoint.prometheus.enabled=true
  management.metrics.distribution.percentiles-histogram.http.server.requests=true
  management.metrics.distribution.percentiles.http.server.requests=0.5, 0.75, 0.9, 0.95, 0.99, 1.0
  management.metrics.tags.system=ecs
  management.metrics.tags.service=pet-clinic-on-ecs
  management.metrics.tags.env=sandbox
  ```

### `logback.xml`
- `./src/main/resources/`に`logback.xml`を新規作成し、以下内容を追記  
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
      <encoder>
        <pattern>%d{HH:mm:ss.SSS} trace_id=%X{trace_id} span_id=%X{span_id} trace_flags=%X{trace_flags} %msg%n</pattern>
      </encoder>
    </appender>

    <!-- Just wrap your logging appender, for example ConsoleAppender, with OpenTelemetryAppender -->
    <appender name="OTEL" class="io.opentelemetry.instrumentation.logback.mdc.v1_0.OpenTelemetryAppender">
      <appender-ref ref="CONSOLE"/>
    </appender>

    <!-- Use the wrapped "OTEL" appender instead of the original "CONSOLE" one -->
    <root level="INFO">
      <appender-ref ref="OTEL"/>
    </root>

  </configuration>
  ```
- 参考URL
  - https://github.com/open-telemetry/opentelemetry-java-instrumentation/blob/main/docs/logger-mdc-instrumentation.md
  - https://github.com/open-telemetry/opentelemetry-java-instrumentation/tree/main/instrumentation/logback/logback-mdc-1.0/library

# Build
- コンテナイメージ作成  
  ```
  ./mvnw spring-boot:build-image
  ```
- 作成された`spring-petclinic:3.3.0-SNAPSHOT`イメージをECRにプッシュ

# 確認できたこと
- CloudWatch LogsにJavaアプリログがTraceID、SpanIDと一緒に連携されていること
- Thanosに連携されたOpenTelemetry Java agentが生成したメトリクスにExemplarsが設定されていること
  - Grafanaの設定でメトリクスからトレースに飛べることも確認
- トレースのバックエンド（Jaeger、X-Ray）にトレースが連携されていること