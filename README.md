# bdget 🎓

Microservicio REST en **Java 17 + Spring Boot 3** para gestión de estudiantes (CRUD). Incluye tests unitarios, manejo de excepciones y persistencia vía Spring Data JPA.

Este repositorio es la **base de trabajo** para la Evaluación Parcial N°1 de Ingeniería DevOps (DOY0101) — nivel avanzado. A partir de este punto, cada equipo debe construir su propio flujo de trabajo colaborativo aplicando Git, GitHub y GitHub Actions.

---

## 🚀 Cómo levantar el proyecto localmente

Requiere JDK 17 y Maven (o usa el wrapper incluido, `./mvnw`, que no requiere Maven instalado).

```bash
./mvnw spring-boot:run
```

La API queda disponible en `http://localhost:8080/students`. La base de datos es **H2 en memoria** — no requiere instalación ni credenciales, y se reinicia cada vez que se detiene la aplicación. Mientras la app está corriendo, puedes inspeccionar los datos en `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:mem:bdgetdb`, usuario: `sa`, sin contraseña).

Para correr los tests:
```bash
./mvnw test
```

---

## 📁 Estructura del proyecto

```
bdget/
├── .github/workflows/     → automatización CI/CD
├── src/main/java/...      → código fuente (modelo, controlador, servicio, repositorio)
├── src/test/java/...      → tests unitarios
├── src/main/resources/    → configuración (application.properties)
├── Dockerfile              → imagen de contenedor (opcional)
├── pom.xml                 → dependencias del proyecto (Maven)
└── README.md
```

> ✏️ **A completar por el equipo.**
> Actualicen este diagrama si agregan nuevos paquetes, clases o carpetas.

---

## 🌳 Estrategia de ramificación

> ✏️ **A completar por el equipo.**
> Indiquen aquí si optaron por **GitFlow** o **Trunk-Based Development**, y justifiquen la elección considerando el tamaño del proyecto, la frecuencia de cambios esperada, y el tipo de equipo (2 personas).

---

## 📝 Convenciones de commits

> ✏️ **A completar por el equipo.**
> Documenten aquí el formato que van a usar para sus mensajes de commit (ej. `feat: agrega endpoint de búsqueda por nombre`, `fix: corrige validación de nombre vacío`), y por qué eligieron ese formato.

---

## 🔀 Convenciones de naming de ramas

> ✏️ **A completar por el equipo.**
> Ejemplo de formato a definir: `feature/<nombre-descriptivo>`, `hotfix/<nombre-descriptivo>`. Expliquen brevemente el criterio que usaron.

---

## 🔍 Estrategia de revisión (Pull Requests)

> ✏️ **A completar por el equipo.**
> ¿Cómo revisaron los cambios antes de fusionarlos a `develop` o `main`? ¿Qué debía cumplir un Pull Request para ser aprobado?

---

## ⚙️ Automatización (CI/CD)

Este repositorio incluye un workflow base en `.github/workflows/main.yml` que:
- Ejecuta los tests unitarios (`mvn test`) en cada `push` a `develop`
- Compila y empaqueta el proyecto en cada Pull Request hacia `main`

> ✏️ **A completar por el equipo.**
> Pueden extender este workflow (por ejemplo, agregando un paso de análisis de código, un linter, o construcción de la imagen Docker). Documenten aquí qué automatizaron, por qué, y qué rol cumple dentro de un proceso CI/CD real.

---

## 🐳 Docker (opcional)

El proyecto incluye un `Dockerfile` funcional. Para construir y correr la imagen localmente:

```bash
docker build -t bdget .
docker run -p 8080:8080 bdget
```

---

## 👥 Autores

- Integrante 1 — nombre completo
- Integrante 2 — nombre completo
