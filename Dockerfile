FROM eclipse-temurin:17-jdk AS buildstage

RUN apt-get update && apt-get install -y maven

WORKDIR /app

COPY pom.xml .
COPY src /app/src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre

COPY --from=buildstage /app/target/bdget-0.0.1-SNAPSHOT.jar /app/bdget.jar

EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "/app/bdget.jar" ]
