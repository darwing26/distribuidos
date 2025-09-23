# Índice de Diagramas UML - Sistema Distribuido de Procesamiento de Imágenes

Este documento contiene un conjunto completo de diagramas UML que documentan la arquitectura, diseño y comportamiento del sistema distribuido de procesamiento de imágenes.

## 📋 Índice de Diagramas

### 1. 🏗️ [Diagrama de Clases](./class_diagram.md)
**Propósito**: Muestra la estructura estática del sistema, incluyendo clases, interfaces, relaciones y responsabilidades.

**Contenido**:
- Entidades de dominio (User, Node, JobBatch, ImageTask)
- Servicios y controladores (FastAPIApp, DatabaseService, GRPCClient, WorkerService)
- DTOs y schemas de comunicación
- Mensajes Protobuf para gRPC
- Relaciones y dependencias entre componentes

**Cuándo usar**: Para entender la estructura del código, las responsabilidades de cada clase y las relaciones entre componentes.

---

### 2. 🏛️ [Diagrama de Arquitectura](./architecture_diagram.md)
**Propósito**: Presenta la arquitectura de alto nivel del sistema, mostrando las capas principales y los protocolos de comunicación.

**Contenido**:
- Capa de presentación (Web Client)
- Capa de aplicación (FastAPI Server con APIs especializadas)
- Capa de servicios (gRPC Client, Database Service, Schema Validation)
- Capa de datos (SQLite Database, File System)
- Capa de workers (Nodos de procesamiento distribuido)
- Protocolos de comunicación (HTTP/REST, gRPC/Protobuf)

**Cuándo usar**: Para comprender la estructura general del sistema, las tecnologías utilizadas y los patrones arquitectónicos implementados.

---

### 3. 🧩 [Diagrama de Componentes](./component_diagram.md)
**Propósito**: Detalla los componentes del sistema y sus interfaces, mostrando cómo se organizan y comunican.

**Contenido**:
- Componentes Web Client (UI, Controller, HTTP Client)
- Componentes API Server (Controllers especializados por dominio)
- Componentes Data Access (Repositories, Database Manager)
- Componentes gRPC (Manager, Health Checker, Task Submitter)
- Componentes Worker Node (gRPC Server, Image Processor, Task Executor)
- Componentes de esquemas y protocolos

**Cuándo usar**: Para entender la modularidad del sistema, las responsabilidades específicas de cada componente y las interfaces entre ellos.

---

### 4. 🎯 [Diagrama de Dominio](./domain_diagram.md)
**Propósito**: Modela el dominio del negocio usando Domain-Driven Design (DDD), incluyendo agregados, entidades, value objects y servicios de dominio.

**Contenido**:
- Agregados de dominio (User, Node, JobBatch)
- Entidades y value objects
- Servicios de dominio (TaskDistribution, NodeHealthMonitoring, BatchProcessing)
- Eventos de dominio
- Invariantes y reglas de negocio

**Cuándo usar**: Para comprender la lógica de negocio, las reglas del dominio y cómo se modelan los conceptos del mundo real.

---

### 5. 🎭 [Diagrama de Casos de Uso](./use_case_diagram.md)
**Propósito**: Identifica los actores del sistema y los casos de uso que pueden realizar, mostrando las funcionalidades desde la perspectiva del usuario.

**Contenido**:
- Actores (Usuario, Administrador, Nodo Worker, Sistema Externo)
- Casos de uso de autenticación
- Casos de uso de gestión de nodos
- Casos de uso de procesamiento de imágenes
- Casos de uso de monitoreo y administración
- Relaciones include, extend y dependencias

**Cuándo usar**: Para entender qué puede hacer cada tipo de usuario en el sistema y cómo interactúan con las funcionalidades.

---

### 6. 🔄 [Diagrama de Secuencia](./sequence_diagram.md)
**Propósito**: Muestra las interacciones entre objetos a lo largo del tiempo para diferentes escenarios del sistema.

**Contenido**:
- Flujo de registro de usuario
- Flujo de registro de nodo worker
- Flujo de health check de nodos
- Flujo de envío de lote de procesamiento
- Flujo de procesamiento de tarea
- Flujo de consulta de estado de lote
- Flujo de subida de archivos
- Flujo de arranque del sistema

**Cuándo usar**: Para entender cómo fluye la información entre componentes durante operaciones específicas y el orden temporal de las interacciones.

---

### 7. ⚡ [Diagrama de Actividades](./activity_diagram.md)
**Propósito**: Representa los flujos de trabajo y procesos del sistema, incluyendo decisiones, paralelismo y manejo de errores.

**Contenido**:
- Flujo de procesamiento de lote de imágenes
- Flujo de registro y monitoreo de nodos
- Flujo de monitoreo del sistema
- Gestión de concurrencia y paralelismo
- Manejo de errores y recuperación
- Optimización y balanceo de carga

**Cuándo usar**: Para comprender los procesos de negocio, los flujos de trabajo complejos y cómo el sistema maneja diferentes escenarios.

---

### 8. 🔄 [Diagrama de Estados](./state_diagram.md)
**Propósito**: Modela los diferentes estados que pueden tener los objetos del sistema y las transiciones entre ellos.

**Contenido**:
- Estados del nodo worker
- Estados del lote de procesamiento
- Estados de la tarea individual
- Estados del sistema distribuido
- Estados de la conexión gRPC
- Transiciones y condiciones de cambio de estado

**Cuándo usar**: Para entender el ciclo de vida de los objetos del sistema y cómo cambian de estado en respuesta a eventos.

---

## 🛠️ Herramientas y Tecnologías

### Lenguaje de Diagramas
- **Mermaid**: Utilizado para todos los diagramas por su simplicidad y compatibilidad con Markdown
- **Sintaxis UML**: Siguiendo las convenciones estándar de UML 2.5

### Tecnologías del Sistema
- **Backend**: FastAPI (Python) con SQLModel para ORM
- **Base de Datos**: SQLite para persistencia local
- **Comunicación**: gRPC/Protobuf para comunicación distribuida, HTTP/REST para API pública
- **Frontend**: HTML5/CSS3/JavaScript vanilla
- **Arquitectura**: Microservicios distribuidos con patrón de capas

## 📚 Cómo Usar Esta Documentación

### Para Desarrolladores
1. **Nuevos en el proyecto**: Comenzar con Arquitectura → Componentes → Clases
2. **Implementando funcionalidades**: Revisar Casos de Uso → Secuencia → Actividades
3. **Debugging**: Consultar Estados → Secuencia → Componentes

### Para Arquitectos
1. **Evaluación de arquitectura**: Arquitectura → Componentes → Dominio
2. **Planificación de cambios**: Todos los diagramas para impacto completo
3. **Documentación de decisiones**: Usar como base para ADRs

### Para QA/Testing
1. **Casos de prueba**: Casos de Uso → Secuencia → Estados
2. **Pruebas de integración**: Componentes → Arquitectura
3. **Pruebas de flujo**: Actividades → Secuencia

### Para Product Managers
1. **Funcionalidades**: Casos de Uso → Dominio
2. **Flujos de usuario**: Actividades → Secuencia
3. **Impacto de cambios**: Dominio → Casos de Uso

## 🔄 Mantenimiento de los Diagramas

### Cuándo Actualizar
- **Cambios en la arquitectura**: Actualizar Arquitectura y Componentes
- **Nuevas funcionalidades**: Actualizar Casos de Uso, Secuencia y Actividades
- **Cambios en el modelo de datos**: Actualizar Clases y Dominio
- **Cambios en flujos**: Actualizar Estados y Actividades

### Versionado
- Los diagramas deben mantenerse sincronizados con el código
- Usar branches para cambios grandes en arquitectura
- Documentar cambios significativos en changelog

---

*Esta documentación UML proporciona una vista completa del sistema distribuido de procesamiento de imágenes, facilitando su comprensión, mantenimiento y evolución.*