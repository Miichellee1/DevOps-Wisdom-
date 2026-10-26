# ==============================================================
# Etapa 1: Build y empaquetado del microservicio (Maven + JDK 17)
# ==============================================================
FROM maven:3.9-eclipse-temurin-17 AS buildstage

WORKDIR /app

# Se copian primero las dependencias para aprovechar la cache de capas:
# si solo cambia el codigo fuente, no se vuelven a descargar las librerias
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Compilacion y empaquetado del artefacto ejecutable (las pruebas ya corren en el pipeline)
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ==============================================================
# Etapa 2: Imagen final de ejecucion liviana y segura (JRE 17 Alpine)
# ==============================================================
FROM eclipse-temurin:17-jre-alpine

# Metadatos del contenedor (Estandar OCI). Revision y fecha se inyectan desde el pipeline
ARG GIT_COMMIT=local
ARG APP_VERSION=local
LABEL org.opencontainers.image.title="bdget" \
      org.opencontainers.image.description="Microservicio REST Spring Boot de gestion de estudiantes" \
      org.opencontainers.image.source="https://github.com/Miichellee1/DevOps-Wisdom-" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.version="${APP_VERSION}"

# Seguridad: se aplican los parches del sistema operativo base y se crea un usuario
# sin privilegios con UID/GID fijos (los usa Kubernetes en runAsUser)
RUN apk upgrade --no-cache && \
    addgroup -S -g 1001 appgroup && adduser -S -u 1001 -G appgroup -s /sbin/nologin appuser

WORKDIR /app

# Copiar artefacto desde la etapa de compilacion con el dueno correcto
COPY --from=buildstage --chown=appuser:appgroup /app/target/bdget.jar /app/bdget.jar

# Ejecutar como usuario no privilegiado
USER 1001:1001

# Puerto expuesto por el microservicio
EXPOSE 8080

# Parametros JVM para contenedores: respeta los limites de CPU/RAM del orquestador
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom" \
    GIT_COMMIT=${GIT_COMMIT} \
    APP_VERSION=${APP_VERSION}

# Verificacion de salud nativa del contenedor contra Spring Boot Actuator
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health/readiness > /dev/null || exit 1

# Forma exec: java es el PID 1 y recibe SIGTERM para un apagado ordenado
ENTRYPOINT ["java", "-jar", "/app/bdget.jar"]
