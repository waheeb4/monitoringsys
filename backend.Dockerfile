FROM maven:3.9.15-eclipse-temurin-25 AS deps

WORKDIR /app

COPY dxc-backend/pom.xml .

RUN mvn dependency:go-offline

FROM maven:3.9.15-eclipse-temurin-25 AS build

WORKDIR /app

COPY --from=deps /root/.m2 /root/.m2
COPY --from=deps /app/pom.xml .

COPY dxc-backend/src src

RUN mvn package -DskipTests

FROM eclipse-temurin:25-jre

WORKDIR /app

COPY --from=build /app/target/DXCproject-0.0.1-SNAPSHOT.jar app.jar

CMD ["java", "-jar", "app.jar"]
