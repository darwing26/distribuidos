# Diagrama de Clases UML - Sistema Distribuido de Procesamiento de Imágenes

```mermaid
classDiagram
    %% ===== ENTIDADES DE DOMINIO =====
    class User {
        -int id
        -string email
        -string name
        -datetime created_at
        +__init__(email: string, name: string)
    }

    class Node {
        -int id
        -string name
        -string host
        -int port
        -string status
        -datetime last_heartbeat
        +__init__(name: string, host: string, port: int)
        +is_active() boolean
        +update_heartbeat() void
    }

    class JobBatch {
        -int id
        -int user_id
        -datetime created_at
        -string status
        -string note
        +__init__(user_id: int, note: string)
        +add_task(task: ImageTask) void
        +get_tasks() List~ImageTask~
        +update_status(status: string) void
    }

    class ImageTask {
        -int id
        -int batch_id
        -string image_id
        -string transformations
        -datetime received_at
        -datetime processed_at
        -int node_id
        -string result_path
        -string status
        -string log
        +__init__(batch_id: int, image_id: string, transformations: string)
        +assign_to_node(node_id: int) void
        +mark_completed(result_path: string) void
        +mark_failed(error_msg: string) void
    }

    %% ===== SERVICIOS Y CONTROLADORES =====
    class FastAPIApp {
        -CORSMiddleware middleware
        +startup() void
        +signup(req: SignupRequest) dict
        +login(req: LoginRequest) dict
        +register_node(req: NodeRegister) NodeOut
        +list_nodes() List~NodeOut~
        +ping_node(node_id: int) dict
        +submit_batch(req: BatchSubmit) BatchOut
        +batch_status(batch_id: int) dict
        +dispatch_test(batch_id: int, node_id: int) dict
        +upload_files(files: List~UploadFile~) dict
    }

    class DatabaseService {
        -Engine engine
        +init_db() void
        +get_session() Session
    }

    class GRPCClient {
        +health_check(node: NodeAddr) string
        +submit_task(node: NodeAddr, request_id: string, image_id: string, operation: string) TransformReply
    }

    class WorkerService {
        +Health(request: HealthRequest) HealthReply
        +SubmitTask(request: TransformTask) TransformReply
        -simulate_processing() void
    }

    %% ===== DTOs Y SCHEMAS =====
    class SignupRequest {
        +string email
        +string name
    }

    class LoginRequest {
        +string email
    }

    class NodeRegister {
        +string name
        +string host
        +int port
    }

    class NodeOut {
        +int id
        +string name
        +string host
        +int port
        +string status
    }

    class TransformDef {
        +string image_id
        +List~string~ operations
    }

    class BatchSubmit {
        +int user_id
        +List~TransformDef~ images
        +string note
    }

    class BatchOut {
        +int batch_id
        +string status
    }

    class NodeAddr {
        +string host
        +int port
    }

    %% ===== PROTOBUF MESSAGES =====
    class HealthRequest {
    }

    class HealthReply {
        +string status
    }

    class TransformTask {
        +string request_id
        +string image_id
        +string operation
    }

    class TransformReply {
        +string request_id
        +string image_id
        +string status
        +string result_path
        +string log_message
    }

    %% ===== RELACIONES =====
    User ||--o{ JobBatch : "crea"
    JobBatch ||--o{ ImageTask : "contiene"
    Node ||--o{ ImageTask : "procesa"
    
    FastAPIApp --> DatabaseService : "usa"
    FastAPIApp --> GRPCClient : "usa"
    FastAPIApp --> User : "maneja"
    FastAPIApp --> Node : "maneja"
    FastAPIApp --> JobBatch : "maneja"
    FastAPIApp --> ImageTask : "maneja"
    
    FastAPIApp --> SignupRequest : "recibe"
    FastAPIApp --> LoginRequest : "recibe"
    FastAPIApp --> NodeRegister : "recibe"
    FastAPIApp --> BatchSubmit : "recibe"
    FastAPIApp --> NodeOut : "retorna"
    FastAPIApp --> BatchOut : "retorna"
    
    GRPCClient --> NodeAddr : "usa"
    GRPCClient --> TransformTask : "envía"
    GRPCClient --> TransformReply : "recibe"
    
    WorkerService --> HealthRequest : "recibe"
    WorkerService --> HealthReply : "retorna"
    WorkerService --> TransformTask : "recibe"
    WorkerService --> TransformReply : "retorna"
    
    BatchSubmit --> TransformDef : "contiene"

    %% ===== NOTAS =====
    note for User "Entidad de usuario del sistema"
    note for Node "Representa un nodo worker en el cluster"
    note for JobBatch "Agrupa tareas de procesamiento de imágenes"
    note for ImageTask "Tarea individual de transformación de imagen"
    note for FastAPIApp "API REST principal del sistema"
    note for WorkerService "Servicio gRPC en cada nodo worker"
```

## Descripción de las Clases

### Entidades de Dominio
- **User**: Representa a los usuarios del sistema que pueden enviar trabajos de procesamiento
- **Node**: Representa un nodo worker en el cluster distribuido
- **JobBatch**: Agrupa múltiples tareas de procesamiento de imágenes en un lote
- **ImageTask**: Representa una tarea individual de transformación de imagen

### Servicios
- **FastAPIApp**: API REST principal que maneja todas las operaciones del sistema
- **DatabaseService**: Maneja la conexión y operaciones con la base de datos SQLite
- **GRPCClient**: Cliente gRPC para comunicarse con los nodos workers
- **WorkerService**: Servicio gRPC que se ejecuta en cada nodo worker

### DTOs (Data Transfer Objects)
- Clases de request/response para la comunicación entre el cliente y el servidor
- Mensajes Protobuf para la comunicación gRPC entre servidor y workers

### Relaciones Principales
- Un usuario puede crear múltiples lotes de trabajo
- Un lote contiene múltiples tareas de imagen
- Los nodos procesan las tareas asignadas
- El sistema usa gRPC para la comunicación distribuida