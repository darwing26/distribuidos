# Diagrama de Componentes UML - Sistema Distribuido de Procesamiento de Imágenes

```mermaid
graph TB
    %% ===== COMPONENTE WEB CLIENT =====
    subgraph "Web Client Component"
        WebUI["`**Web UI**
        <<component>>
        - index.html
        - styles.css
        - JavaScript functions`"]
        
        UIController["`**UI Controller**
        <<component>>
        - Event handlers
        - API calls
        - DOM manipulation`"]
        
        HTTPClient["`**HTTP Client**
        <<component>>
        - Fetch API
        - JSON handling
        - Error management`"]
    end

    %% ===== COMPONENTE API SERVER =====
    subgraph "API Server Component"
        FastAPICore["`**FastAPI Core**
        <<component>>
        - Application instance
        - Middleware setup
        - Route registration`"]
        
        AuthController["`**Authentication Controller**
        <<component>>
        - signup()
        - login()
        - User validation`"]
        
        NodesController["`**Nodes Controller**
        <<component>>
        - register_node()
        - list_nodes()
        - ping_node()`"]
        
        BatchController["`**Batch Controller**
        <<component>>
        - submit_batch()
        - batch_status()
        - dispatch_test()`"]
        
        FilesController["`**Files Controller**
        <<component>>
        - upload_files()
        - File handling`"]
    end

    %% ===== COMPONENTE DATA ACCESS =====
    subgraph "Data Access Component"
        DatabaseManager["`**Database Manager**
        <<component>>
        - init_db()
        - get_session()
        - Connection pooling`"]
        
        UserRepository["`**User Repository**
        <<component>>
        - User CRUD operations
        - Query methods`"]
        
        NodeRepository["`**Node Repository**
        <<component>>
        - Node registration
        - Status updates
        - Health tracking`"]
        
        BatchRepository["`**Batch Repository**
        <<component>>
        - Batch management
        - Task coordination
        - Status tracking`"]
        
        TaskRepository["`**Task Repository**
        <<component>>
        - Task CRUD
        - Assignment logic
        - Result tracking`"]
    end

    %% ===== COMPONENTE GRPC CLIENT =====
    subgraph "gRPC Client Component"
        GRPCManager["`**gRPC Manager**
        <<component>>
        - Channel management
        - Connection pooling
        - Error handling`"]
        
        HealthChecker["`**Health Checker**
        <<component>>
        - health_check()
        - Node monitoring
        - Status validation`"]
        
        TaskSubmitter["`**Task Submitter**
        <<component>>
        - submit_task()
        - Request formatting
        - Response handling`"]
    end

    %% ===== COMPONENTE SCHEMAS =====
    subgraph "Schema Component"
        RequestSchemas["`**Request Schemas**
        <<component>>
        - SignupRequest
        - LoginRequest
        - NodeRegister
        - BatchSubmit`"]
        
        ResponseSchemas["`**Response Schemas**
        <<component>>
        - NodeOut
        - BatchOut
        - Status responses`"]
        
        DataModels["`**Data Models**
        <<component>>
        - User
        - Node
        - JobBatch
        - ImageTask`"]
    end

    %% ===== COMPONENTE WORKER NODE =====
    subgraph "Worker Node Component"
        GRPCServer["`**gRPC Server**
        <<component>>
        - Server setup
        - Service registration
        - Request handling`"]
        
        WorkerServiceImpl["`**Worker Service Implementation**
        <<component>>
        - Health()
        - SubmitTask()
        - Business logic`"]
        
        ImageProcessor["`**Image Processor**
        <<component>>
        - Transformation algorithms
        - File I/O operations
        - Processing pipeline`"]
        
        TaskExecutor["`**Task Executor**
        <<component>>
        - Task scheduling
        - Resource management
        - Result generation`"]
    end

    %% ===== COMPONENTE PROTOBUF =====
    subgraph "Protocol Buffer Component"
        ProtoDefinitions["`**Proto Definitions**
        <<component>>
        - worker.proto
        - Message definitions
        - Service contracts`"]
        
        GeneratedStubs["`**Generated Stubs**
        <<component>>
        - worker_pb2.py
        - worker_pb2_grpc.py
        - Client/Server stubs`"]
    end

    %% ===== COMPONENTE DATABASE =====
    subgraph "Database Component"
        SQLiteEngine["`**SQLite Engine**
        <<component>>
        - Database file
        - Connection management
        - Transaction handling`"]
        
        SchemaManager["`**Schema Manager**
        <<component>>
        - Table creation
        - Migrations
        - Constraints`"]
    end

    %% ===== INTERFACES Y CONEXIONES =====
    WebUI --> UIController
    UIController --> HTTPClient
    HTTPClient -.->|HTTP/JSON| FastAPICore

    FastAPICore --> AuthController
    FastAPICore --> NodesController
    FastAPICore --> BatchController
    FastAPICore --> FilesController

    AuthController --> UserRepository
    NodesController --> NodeRepository
    NodesController --> HealthChecker
    BatchController --> BatchRepository
    BatchController --> TaskRepository
    BatchController --> TaskSubmitter
    FilesController --> DatabaseManager

    UserRepository --> DatabaseManager
    NodeRepository --> DatabaseManager
    BatchRepository --> DatabaseManager
    TaskRepository --> DatabaseManager
    DatabaseManager --> SQLiteEngine

    HealthChecker --> GRPCManager
    TaskSubmitter --> GRPCManager
    GRPCManager -.->|gRPC| GRPCServer

    GRPCServer --> WorkerServiceImpl
    WorkerServiceImpl --> TaskExecutor
    TaskExecutor --> ImageProcessor

    AuthController --> RequestSchemas
    AuthController --> ResponseSchemas
    NodesController --> RequestSchemas
    NodesController --> ResponseSchemas
    BatchController --> RequestSchemas
    BatchController --> ResponseSchemas

    UserRepository --> DataModels
    NodeRepository --> DataModels
    BatchRepository --> DataModels
    TaskRepository --> DataModels

    GRPCManager --> GeneratedStubs
    GRPCServer --> GeneratedStubs
    GeneratedStubs --> ProtoDefinitions

    SQLiteEngine --> SchemaManager

    %% ===== ESTILOS =====
    classDef webComponent fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef apiComponent fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef dataComponent fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef grpcComponent fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef workerComponent fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef schemaComponent fill:#f1f8e9,stroke:#689f38,stroke-width:2px
    classDef dbComponent fill:#ede7f6,stroke:#512da8,stroke-width:2px

    class WebUI,UIController,HTTPClient webComponent
    class FastAPICore,AuthController,NodesController,BatchController,FilesController apiComponent
    class DatabaseManager,UserRepository,NodeRepository,BatchRepository,TaskRepository dataComponent
    class GRPCManager,HealthChecker,TaskSubmitter grpcComponent
    class GRPCServer,WorkerServiceImpl,ImageProcessor,TaskExecutor workerComponent
    class RequestSchemas,ResponseSchemas,DataModels,ProtoDefinitions,GeneratedStubs schemaComponent
    class SQLiteEngine,SchemaManager dbComponent
```

## Descripción de Componentes

### Componentes Web Client
- **Web UI**: Interfaz de usuario HTML/CSS/JavaScript
- **UI Controller**: Maneja eventos y lógica de presentación
- **HTTP Client**: Comunicación con la API REST

### Componentes API Server
- **FastAPI Core**: Núcleo de la aplicación web
- **Controllers**: Manejan las rutas y lógica de negocio específica por dominio
- Separación clara de responsabilidades por funcionalidad

### Componentes Data Access
- **Database Manager**: Gestiona conexiones y sesiones de base de datos
- **Repositories**: Patrón Repository para cada entidad del dominio
- Abstracción completa del acceso a datos

### Componentes gRPC Client
- **gRPC Manager**: Gestiona las conexiones gRPC
- **Specialized Services**: Servicios específicos para salud y tareas
- Manejo robusto de comunicación distribuida

### Componentes Worker Node
- **gRPC Server**: Servidor de servicios distribuidos
- **Worker Service**: Implementación de la lógica de procesamiento
- **Image Processor**: Motor de transformación de imágenes
- **Task Executor**: Coordinador de ejecución de tareas

### Interfaces y Protocolos
- **REST API**: Comunicación cliente-servidor
- **gRPC**: Comunicación servidor-workers
- **Protocol Buffers**: Definición de contratos de comunicación
- **SQLite**: Persistencia de datos

### Beneficios del Diseño
1. **Separación de Responsabilidades**: Cada componente tiene un propósito específico
2. **Bajo Acoplamiento**: Interfaces bien definidas entre componentes
3. **Alta Cohesión**: Funcionalidad relacionada agrupada
4. **Reutilización**: Componentes pueden ser reutilizados en diferentes contextos
5. **Testabilidad**: Cada componente puede ser probado independientemente