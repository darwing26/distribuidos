# Diagrama de Arquitectura UML - Sistema Distribuido de Procesamiento de Imágenes

```mermaid
graph TB
    %% ===== CAPA DE PRESENTACIÓN =====
    subgraph "Presentation Layer"
        WebClient["`**Web Client**
        HTML5 + CSS3 + JavaScript
        - Panel de Control
        - Gestión de Nodos
        - Monitoreo de Trabajos`"]
    end

    %% ===== CAPA DE APLICACIÓN =====
    subgraph "Application Layer"
        subgraph "FastAPI Server"
            AuthAPI["`**Authentication API**
            /auth/signup
            /auth/login`"]
            
            NodesAPI["`**Nodes Management API**
            /nodes/register
            /nodes
            /nodes/{id}/ping`"]
            
            BatchAPI["`**Batch Processing API**
            /batches/submit
            /batches/{id}/status
            /batches/{id}/dispatch_test/{node_id}`"]
            
            FilesAPI["`**File Management API**
            /files/upload`"]
        end
        
        CORS["`**CORS Middleware**
        Cross-Origin Support`"]
    end

    %% ===== CAPA DE SERVICIOS =====
    subgraph "Service Layer"
        GRPCClient["`**gRPC Client**
        - health_check()
        - submit_task()
        - NodeAddr management`"]
        
        DBService["`**Database Service**
        - init_db()
        - get_session()
        - SQLModel operations`"]
        
        SchemaValidation["`**Schema Validation**
        Pydantic Models
        - Request/Response DTOs
        - Data validation`"]
    end

    %% ===== CAPA DE PERSISTENCIA =====
    subgraph "Data Layer"
        SQLiteDB["`**SQLite Database**
        Tables:
        - users
        - nodes  
        - jobbatches
        - imagetasks`"]
        
        FileSystem["`**File System**
        - Uploaded images
        - Processed results
        - Logs`"]
    end

    %% ===== CAPA DE WORKERS =====
    subgraph "Worker Nodes Layer"
        subgraph "Worker Node 1"
            WorkerService1["`**Worker gRPC Service**
            Port: 50051
            - Health()
            - SubmitTask()`"]
            
            ImageProcessor1["`**Image Processor**
            - Grayscale conversion
            - Resize operations
            - Format transformations`"]
        end
        
        subgraph "Worker Node 2"
            WorkerService2["`**Worker gRPC Service**
            Port: 50052
            - Health()
            - SubmitTask()`"]
            
            ImageProcessor2["`**Image Processor**
            - Grayscale conversion
            - Resize operations
            - Format transformations`"]
        end
        
        subgraph "Worker Node N"
            WorkerServiceN["`**Worker gRPC Service**
            Port: 5005N
            - Health()
            - SubmitTask()`"]
            
            ImageProcessorN["`**Image Processor**
            - Grayscale conversion
            - Resize operations
            - Format transformations`"]
        end
    end

    %% ===== PROTOCOLOS DE COMUNICACIÓN =====
    subgraph "Communication Protocols"
        HTTP["`**HTTP/REST**
        Client ↔ API Server
        JSON payloads`"]
        
        GRPC["`**gRPC/Protobuf**
        API Server ↔ Workers
        Binary protocol`"]
        
        SQLProtocol["`**SQLite Protocol**
        Local file-based DB`"]
    end

    %% ===== CONEXIONES =====
    WebClient -.->|HTTP/JSON| CORS
    CORS --> AuthAPI
    CORS --> NodesAPI
    CORS --> BatchAPI
    CORS --> FilesAPI

    AuthAPI --> DBService
    NodesAPI --> DBService
    NodesAPI --> GRPCClient
    BatchAPI --> DBService
    BatchAPI --> GRPCClient
    FilesAPI --> FileSystem

    DBService --> SQLiteDB
    GRPCClient -.->|gRPC| WorkerService1
    GRPCClient -.->|gRPC| WorkerService2
    GRPCClient -.->|gRPC| WorkerServiceN

    WorkerService1 --> ImageProcessor1
    WorkerService2 --> ImageProcessor2
    WorkerServiceN --> ImageProcessorN

    AuthAPI --> SchemaValidation
    NodesAPI --> SchemaValidation
    BatchAPI --> SchemaValidation
    FilesAPI --> SchemaValidation

    %% ===== ESTILOS =====
    classDef presentation fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef application fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef service fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef data fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef worker fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef protocol fill:#f1f8e9,stroke:#33691e,stroke-width:2px

    class WebClient presentation
    class AuthAPI,NodesAPI,BatchAPI,FilesAPI,CORS application
    class GRPCClient,DBService,SchemaValidation service
    class SQLiteDB,FileSystem data
    class WorkerService1,WorkerService2,WorkerServiceN,ImageProcessor1,ImageProcessor2,ImageProcessorN worker
    class HTTP,GRPC,SQLProtocol protocol
```

## Características Arquitectónicas

### Patrones Implementados
1. **Layered Architecture**: Separación clara en capas de presentación, aplicación, servicios y datos
2. **Microservices Pattern**: Workers como servicios independientes
3. **API Gateway Pattern**: FastAPI actúa como gateway unificado
4. **Repository Pattern**: DBService abstrae el acceso a datos

### Protocolos de Comunicación
- **HTTP/REST**: Cliente web ↔ API Server (JSON)
- **gRPC/Protobuf**: API Server ↔ Workers (binario, alta performance)
- **SQLite**: Persistencia local de datos

### Escalabilidad
- **Horizontal**: Agregar más nodos workers
- **Vertical**: Mejorar recursos de workers individuales
- **Load Balancing**: Distribución de tareas entre workers disponibles

### Tolerancia a Fallos
- **Health Checks**: Monitoreo constante del estado de workers
- **Task Retry**: Posibilidad de reasignar tareas fallidas
- **Graceful Degradation**: El sistema continúa operando con workers reducidos