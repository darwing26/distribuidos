# Diagrama de Casos de Uso UML - Sistema Distribuido de Procesamiento de Imágenes

```mermaid
graph TB
    %% ===== ACTORES =====
    subgraph "Actores"
        Usuario["`**Usuario**
        <<Actor>>
        Usuario del sistema que necesita
        procesar imágenes`"]
        
        Administrador["`**Administrador del Sistema**
        <<Actor>>
        Gestiona nodos y monitorea
        el estado del sistema`"]
        
        WorkerNode["`**Nodo Worker**
        <<Actor>>
        Procesa tareas de transformación
        de imágenes`"]
        
        SistemaExterno["`**Sistema Externo**
        <<Actor>>
        Sistemas que consumen
        la API REST`"]
    end

    %% ===== CASOS DE USO DE AUTENTICACIÓN =====
    subgraph "Gestión de Usuarios"
        UC_Registro["`**UC-001: Registrar Usuario**
        El usuario se registra en el sistema
        proporcionando email y nombre`"]
        
        UC_Login["`**UC-002: Iniciar Sesión**
        El usuario inicia sesión con
        sus credenciales`"]
        
        UC_Autenticar["`**UC-003: Autenticar Requests**
        El sistema valida las requests
        del usuario autenticado`"]
    end

    %% ===== CASOS DE USO DE GESTIÓN DE NODOS =====
    subgraph "Gestión de Nodos Workers"
        UC_RegistrarNodo["`**UC-004: Registrar Nodo Worker**
        Un nodo worker se registra en
        el sistema con su dirección`"]
        
        UC_ListarNodos["`**UC-005: Listar Nodos**
        Ver todos los nodos registrados
        y su estado actual`"]
        
        UC_PingNodo["`**UC-006: Verificar Estado de Nodo**
        Realizar health check a un
        nodo específico`"]
        
        UC_MonitorearNodos["`**UC-007: Monitorear Nodos**
        Supervisar continuamente el
        estado de todos los nodos`"]
        
        UC_DesregistrarNodo["`**UC-008: Desregistrar Nodo**
        Remover un nodo worker
        del sistema`"]
    end

    %% ===== CASOS DE USO DE PROCESAMIENTO =====
    subgraph "Procesamiento de Imágenes"
        UC_SubirArchivos["`**UC-009: Subir Archivos**
        El usuario sube archivos de imagen
        al sistema para procesamiento`"]
        
        UC_CrearLote["`**UC-010: Crear Lote de Procesamiento**
        El usuario crea un lote con
        múltiples imágenes y transformaciones`"]
        
        UC_EnviarTarea["`**UC-011: Enviar Tarea a Worker**
        El sistema distribuye una tarea
        a un nodo worker disponible`"]
        
        UC_ProcesarImagen["`**UC-012: Procesar Imagen**
        Un worker procesa una imagen
        aplicando las transformaciones`"]
        
        UC_ConsultarEstado["`**UC-013: Consultar Estado de Lote**
        El usuario consulta el progreso
        de un lote de procesamiento`"]
        
        UC_ReintentarTarea["`**UC-014: Reintentar Tarea Fallida**
        El sistema reintenta procesar
        una tarea que falló`"]
        
        UC_DescargarResultados["`**UC-015: Descargar Resultados**
        El usuario descarga las imágenes
        procesadas`"]
    end

    %% ===== CASOS DE USO DE MONITOREO =====
    subgraph "Monitoreo y Administración"
        UC_VerEstadoSistema["`**UC-016: Ver Estado del Sistema**
        Visualizar el estado general
        del sistema distribuido`"]
        
        UC_VerMetricas["`**UC-017: Ver Métricas de Rendimiento**
        Consultar métricas de throughput
        y latencia del sistema`"]
        
        UC_GestionarCarga["`**UC-018: Gestionar Carga de Trabajo**
        Distribuir eficientemente las
        tareas entre nodos disponibles`"]
        
        UC_HandleErrores["`**UC-019: Manejar Errores del Sistema**
        Gestionar y resolver errores
        de procesamiento y comunicación`"]
    end

    %% ===== CASOS DE USO DE INTEGRACIÓN =====
    subgraph "Integración y APIs"
        UC_APIRest["`**UC-020: Consumir API REST**
        Sistemas externos consumen
        los servicios vía API REST`"]
        
        UC_ComunicaciongRPC["`**UC-021: Comunicación gRPC**
        Comunicación eficiente entre
        servidor y workers via gRPC`"]
        
        UC_ValidarContratos["`**UC-022: Validar Contratos API**
        Validar requests y responses
        según schemas definidos`"]
    end

    %% ===== RELACIONES ACTOR - CASOS DE USO =====
    Usuario --> UC_Registro
    Usuario --> UC_Login
    Usuario --> UC_SubirArchivos
    Usuario --> UC_CrearLote
    Usuario --> UC_ConsultarEstado
    Usuario --> UC_DescargarResultados

    Administrador --> UC_RegistrarNodo
    Administrador --> UC_ListarNodos
    Administrador --> UC_PingNodo
    Administrador --> UC_MonitorearNodos
    Administrador --> UC_DesregistrarNodo
    Administrador --> UC_VerEstadoSistema
    Administrador --> UC_VerMetricas
    Administrador --> UC_GestionarCarga
    Administrador --> UC_HandleErrores

    WorkerNode --> UC_RegistrarNodo
    WorkerNode --> UC_ProcesarImagen

    SistemaExterno --> UC_APIRest
    SistemaExterno --> UC_ComunicaciongRPC
    SistemaExterno --> UC_ValidarContratos

    %% ===== RELACIONES INCLUDE =====
    UC_Login ..> UC_Autenticar : <<include>>
    UC_CrearLote ..> UC_Autenticar : <<include>>
    UC_SubirArchivos ..> UC_Autenticar : <<include>>
    UC_ConsultarEstado ..> UC_Autenticar : <<include>>
    UC_DescargarResultados ..> UC_Autenticar : <<include>>

    UC_CrearLote ..> UC_EnviarTarea : <<include>>
    UC_EnviarTarea ..> UC_ProcesarImagen : <<include>>
    UC_PingNodo ..> UC_ComunicaciongRPC : <<include>>
    UC_EnviarTarea ..> UC_ComunicaciongRPC : <<include>>

    UC_APIRest ..> UC_ValidarContratos : <<include>>
    UC_ComunicaciongRPC ..> UC_ValidarContratos : <<include>>

    %% ===== RELACIONES EXTEND =====
    UC_ReintentarTarea ..> UC_EnviarTarea : <<extend>>
    UC_HandleErrores ..> UC_MonitorearNodos : <<extend>>
    UC_GestionarCarga ..> UC_EnviarTarea : <<extend>>

    %% ===== DEPENDENCIAS ENTRE CASOS DE USO =====
    UC_CrearLote -.-> UC_SubirArchivos : depends on
    UC_ConsultarEstado -.-> UC_CrearLote : depends on
    UC_DescargarResultados -.-> UC_ProcesarImagen : depends on
    UC_EnviarTarea -.-> UC_ListarNodos : depends on
    UC_ProcesarImagen -.-> UC_RegistrarNodo : depends on

    %% ===== ESTILOS =====
    classDef actor fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef usecase fill:#f8bbd9,stroke:#ad1457,stroke-width:2px,color:#000
    classDef auth fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef nodes fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef processing fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef monitoring fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef integration fill:#e0f2f1,stroke:#00695c,stroke-width:2px

    class Usuario,Administrador,WorkerNode,SistemaExterno actor
    class UC_Registro,UC_Login,UC_Autenticar auth
    class UC_RegistrarNodo,UC_ListarNodos,UC_PingNodo,UC_MonitorearNodos,UC_DesregistrarNodo nodes
    class UC_SubirArchivos,UC_CrearLote,UC_EnviarTarea,UC_ProcesarImagen,UC_ConsultarEstado,UC_ReintentarTarea,UC_DescargarResultados processing
    class UC_VerEstadoSistema,UC_VerMetricas,UC_GestionarCarga,UC_HandleErrores monitoring
    class UC_APIRest,UC_ComunicaciongRPC,UC_ValidarContratos integration
```

## Descripción de Casos de Uso

### Gestión de Usuarios
- **UC-001 Registrar Usuario**: Permite a nuevos usuarios crear una cuenta en el sistema
- **UC-002 Iniciar Sesión**: Autenticación de usuarios existentes
- **UC-003 Autenticar Requests**: Validación de permisos para operaciones protegidas

### Gestión de Nodos Workers
- **UC-004 Registrar Nodo Worker**: Los nodos se auto-registran en el sistema
- **UC-005 Listar Nodos**: Visualización de todos los nodos y su estado
- **UC-006 Verificar Estado de Nodo**: Health check individual de nodos
- **UC-007 Monitorear Nodos**: Supervisión continua del cluster
- **UC-008 Desregistrar Nodo**: Remoción de nodos del sistema

### Procesamiento de Imágenes
- **UC-009 Subir Archivos**: Carga de imágenes al sistema
- **UC-010 Crear Lote de Procesamiento**: Definición de trabajos de transformación
- **UC-011 Enviar Tarea a Worker**: Distribución de tareas al cluster
- **UC-012 Procesar Imagen**: Ejecución de transformaciones en workers
- **UC-013 Consultar Estado de Lote**: Seguimiento del progreso de trabajos
- **UC-014 Reintentar Tarea Fallida**: Recuperación automática de errores
- **UC-015 Descargar Resultados**: Obtención de imágenes procesadas

### Monitoreo y Administración
- **UC-016 Ver Estado del Sistema**: Dashboard del estado general
- **UC-017 Ver Métricas de Rendimiento**: Análisis de performance
- **UC-018 Gestionar Carga de Trabajo**: Optimización de distribución
- **UC-019 Manejar Errores del Sistema**: Gestión de fallos y recuperación

### Integración y APIs
- **UC-020 Consumir API REST**: Interfaz para sistemas externos
- **UC-021 Comunicación gRPC**: Protocolo de comunicación interna
- **UC-022 Validar Contratos API**: Validación de schemas y contratos

## Características del Modelo de Casos de Uso

### Actores Identificados
1. **Usuario**: Persona que utiliza el sistema para procesar imágenes
2. **Administrador**: Gestiona la infraestructura y monitorea el sistema
3. **Nodo Worker**: Sistema automatizado que procesa tareas
4. **Sistema Externo**: Aplicaciones que consumen los servicios

### Relaciones
- **Include**: Dependencias obligatorias entre casos de uso
- **Extend**: Extensiones opcionales que añaden funcionalidad
- **Dependencies**: Relaciones de prerequisitos entre funcionalidades

### Flujos Principales
1. **Flujo de Usuario**: Registro → Login → Subir → Crear Lote → Consultar → Descargar
2. **Flujo de Worker**: Registro → Procesamiento → Reporte de Estado
3. **Flujo de Administrador**: Monitoreo → Gestión → Resolución de Problemas