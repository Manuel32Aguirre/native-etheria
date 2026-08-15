FROM maven:3.9.11-eclipse-temurin-21 AS build

WORKDIR /workspace
COPY pom.xml .
COPY .mvn .mvn
RUN mvn -B dependency:go-offline -DskipTests

COPY src src
RUN mvn -B clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app
COPY --from=build /workspace/target/*.jar app.jar

ENV JAVA_TOOL_OPTIONS="-Xms64m -Xmx256m"
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]