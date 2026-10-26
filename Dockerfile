# ==============================================================
# Etapa 1: Build y empaquetado del microservicio (JDK 17 Temurin)
# ==============================================================
FROM eclipse-temurin:25-jdk AS buildstage

RUN apt-get update && apt-get install -y --no-install-recommends maven && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar dependencias y codigo fuente
COPY pom.xml .
COPY src /app/src

# Compilacion y empaquetado del artefacto ejecutable
RUN mvn clean package -DskipTests

# ==============================================================
# Etapa 2: Imagen final de ejecucion liviana y segura (JRE 17)
# ==============================================================
FROM eclipse-temurin:25-jre

# Metadatos del contenedor (Estandar OCI)
LABEL maintainer="Duoc UC DevOps Team <va.ruizi@duocuc.cl>"
LABEL description="bdget - Microservicio REST Spring Boot de gestion de estudiantes"
LABEL version="1.0.0"

# Seguridad: Creacion de usuario y grupo sin privilegios de root (Hardening)
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

WORKDIR /app

# Copiar artefacto desde la etapa de compilacion y asignar permisos
COPY --from=buildstage /app/target/bdget-0.0.1-SNAPSHOT.jar /app/bdget.jar
RUN chown -R appuser:appgroup /app

# Ejecutar como usuario no privilegiado
USER appuser

# Puerto expuesto por el microservicio
EXPOSE 8080

# Parametros optimizados para ejecucion en entornos de nube y contenedores
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Verificacion de salud nativa del contenedor (HealthCheck)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/students > /dev/null || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/bdget.jar"]
