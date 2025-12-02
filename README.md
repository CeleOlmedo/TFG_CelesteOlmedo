# Proyecto Completo – Flutter + Spring Boot + MySQL #

Este repositorio contiene un proyecto full stack compuesto por:

- **Aplicación móvil en Flutter**
- **API REST en Spring Boot**
- **Base de datos MySQL**

El objetivo es ofrecer una solución completa con frontend y backend integrados, ideal para desarrollo móvil con servidor propio.

---

### 📁 Estructura del proyecto #

TFG_CelesteOlmedo/
│
├── nutricam_proyect/ # App móvil en Flutter
│
└── api/ # Backend REST en Spring Boot

## Requisitos para la ejecución #
Asegurarse de tener instalado lo siguiente:

# 🟡 Flutter
- Descarga desde: https://flutter.dev
- Agregar a las variables de entorno
- Para verificar la instalación utilizar en la terminal: flutter doctor

# 🟢 Visual Studio Code
- Extensión: **Flutter**
- Extensión: **Dart**

# 🔵 Android Studio
- SDKs instalados
- Emulador configurado (Pixel o cualquier dispositivo)

# 🟠 MySQL
- Instalado localmente
- Usuario: `root`
- IMPORTANTE: Recordar la contraseña ingresada
- (Modificar credenciales según tu configuración)
- Crear la base de datos antes de ejecutar la API

#  Base de datos
1. Abrí MySQL o phpMyAdmin  
2. Creá la base de datos: CREATE DATABASE nutricam;
3. Configurar el archivo "application.properties" con la siguiente información:
spring.datasource.url=jdbc:mysql://localhost:3306/nutricam?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=TU_PASSWORD
spring.jpa.hibernate.ddl-auto=update

⚙️ EJECUTAR EL BACKEND
1. Abrir la carpeta api/ en Visual Studio Code (Es necesario tener Java 17 instalado)
2. Ejecutar en terminal: ./mvnw spring-boot:run
3. La API quedará disponible en: http://localhost:8080

📱 EJECUTAR LA APP
1. Abrir la carpeta nutricam_proyect/ en Visual Studio Code
2. Instalar dependencias con el siguiente comando en terminal: flutter pub get
3. Crear y lanzar un emulador desde Android Studio
4. Ejecutar la aplicación con el siguiente comando en terminal: flutter run

# Autor:
# Ailín Celeste Olmedo
# Proyecto Full Stack – Flutter + Spring Boot + MySQL


