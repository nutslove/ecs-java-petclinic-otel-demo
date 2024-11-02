# 目的
- ECS上でJavaアプリ(pet clinic)を動かし、metrics/logs/tracesの連携テストを行うため

# Fork
- 以下リポジトリからFork
  - https://github.com/dockersamples/spring-petclinic-docker

# 加えた変更
### `pom.xml`
- `./pom.xml`に以下を追加  
  ```xml
  <!-- Micrometer Prometheus Registry -->
  <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-registry-prometheus</artifactId>
  </dependency>
  ```