# Diagrama de Dominio UML - Sistema Distribuido de Procesamiento de Imágenes

```mermaid
classDiagram
    %% ===== AGREGADOS DE DOMINIO =====
    
    %% Agregado User
    class User {
        <<Entity>>
        <<AggregateRoot>>
        -UserId id
        -Email email
        -UserName name
        -CreatedAt created_at
        +register(email: Email, name: UserName) User
        +authenticate(email: Email) boolean
        +createBatch(images: List~ImageSpec~, note: string) JobBatch
        +getBatches() List~JobBatch~
    }

    class Email {
        <<ValueObject>>
        -string value
        +Email(value: string)
        +isValid() boolean
        +toString() string
    }

    class UserName {
        <<ValueObject>>
        -string value
        +UserName(value: string)
        +toString() string
    }

    class UserId {
        <<ValueObject>>
        -int value
        +UserId(value: int)
        +toInt() int
    }

    %% Agregado Node (Worker)
    class Node {
        <<Entity>>
        <<AggregateRoot>>
        -NodeId id
        -NodeName name
        -NetworkAddress address
        -NodeStatus status
        -LastHeartbeat last_heartbeat
        +register(name: NodeName, address: NetworkAddress) Node
        +ping() NodeHealth
        +assignTask(task: ImageTask) TaskAssignment
        +updateStatus(status: NodeStatus) void
        +markAsHealthy() void
        +markAsUnhealthy() void
        +isAvailable() boolean
    }

    class NodeId {
        <<ValueObject>>
        -int value
        +NodeId(value: int)
        +toInt() int
    }

    class NodeName {
        <<ValueObject>>
        -string value
        +NodeName(value: string)
        +toString() string
    }

    class NetworkAddress {
        <<ValueObject>>
        -string host
        -int port
        +NetworkAddress(host: string, port: int)
        +getConnectionString() string
        +isValidPort() boolean
    }

    class NodeStatus {
        <<ValueObject>>
        -string value
        +NodeStatus(value: string)
        +isActive() boolean
        +isInactive() boolean
        +isError() boolean
    }

    class NodeHealth {
        <<ValueObject>>
        -string status
        -datetime timestamp
        +NodeHealth(status: string)
        +isHealthy() boolean
    }

    class LastHeartbeat {
        <<ValueObject>>
        -datetime timestamp
        +LastHeartbeat(timestamp: datetime)
        +isStale(threshold: int) boolean
    }

    %% Agregado JobBatch
    class JobBatch {
        <<Entity>>
        <<AggregateRoot>>
        -BatchId id
        -UserId user_id
        -BatchStatus status
        -CreatedAt created_at
        -BatchNote note
        -List~ImageTask~ tasks
        +createBatch(userId: UserId, images: List~ImageSpec~, note: string) JobBatch
        +addTask(imageSpec: ImageSpec) void
        +assignTasksToNodes(nodes: List~Node~) void
        +updateStatus(status: BatchStatus) void
        +getProgress() BatchProgress
        +isCompleted() boolean
        +hasFailed() boolean
    }

    class BatchId {
        <<ValueObject>>
        -int value
        +BatchId(value: int)
        +toInt() int
    }

    class BatchStatus {
        <<ValueObject>>
        -string value
        +BatchStatus(value: string)
        +isQueued() boolean
        +isProcessing() boolean
        +isDone() boolean
        +isError() boolean
    }

    class BatchNote {
        <<ValueObject>>
        -string value
        +BatchNote(value: string)
        +toString() string
    }

    class BatchProgress {
        <<ValueObject>>
        -int completed
        -int total
        -int failed
        +BatchProgress(completed: int, total: int, failed: int)
        +getPercentage() float
        +isCompleted() boolean
    }

    %% Entidad ImageTask
    class ImageTask {
        <<Entity>>
        -TaskId id
        -BatchId batch_id
        -ImageSpec image_spec
        -TaskStatus status
        -NodeAssignment node_assignment
        -ProcessingResult result
        -TaskTimestamps timestamps
        +createTask(batchId: BatchId, imageSpec: ImageSpec) ImageTask
        +assignToNode(nodeId: NodeId) void
        +markAsProcessing() void
        +markAsCompleted(result: ProcessingResult) void
        +markAsFailed(error: ProcessingError) void
        +canBeRetried() boolean
    }

    class TaskId {
        <<ValueObject>>
        -int value
        +TaskId(value: int)
        +toInt() int
    }

    class ImageSpec {
        <<ValueObject>>
        -ImageId image_id
        -List~TransformationOperation~ operations
        +ImageSpec(imageId: string, operations: List~string~)
        +getImageId() string
        +getOperations() List~TransformationOperation~
        +addOperation(operation: TransformationOperation) void
    }

    class ImageId {
        <<ValueObject>>
        -string value
        +ImageId(value: string)
        +toString() string
    }

    class TransformationOperation {
        <<ValueObject>>
        -string operation_type
        -Map~string,string~ parameters
        +TransformationOperation(type: string, params: Map)
        +getType() string
        +getParameters() Map
        +isValid() boolean
    }

    class TaskStatus {
        <<ValueObject>>
        -string value
        +TaskStatus(value: string)
        +isQueued() boolean
        +isProcessing() boolean
        +isDone() boolean
        +isError() boolean
    }

    class NodeAssignment {
        <<ValueObject>>
        -NodeId node_id
        -datetime assigned_at
        +NodeAssignment(nodeId: NodeId, assignedAt: datetime)
        +getNodeId() NodeId
        +getAssignedAt() datetime
    }

    class ProcessingResult {
        <<ValueObject>>
        -ResultPath result_path
        -ProcessingLog log
        -datetime completed_at
        +ProcessingResult(path: string, log: string, completedAt: datetime)
        +getResultPath() string
        +getLog() string
    }

    class ProcessingError {
        <<ValueObject>>
        -string error_message
        -string error_code
        -datetime occurred_at
        +ProcessingError(message: string, code: string)
        +getMessage() string
        +getCode() string
    }

    class TaskTimestamps {
        <<ValueObject>>
        -datetime received_at
        -datetime processed_at
        +TaskTimestamps(receivedAt: datetime)
        +markAsProcessed() void
        +getProcessingDuration() Duration
    }

    %% ===== SERVICIOS DE DOMINIO =====
    class TaskDistributionService {
        <<DomainService>>
        +distributeTasksToNodes(batch: JobBatch, availableNodes: List~Node~) void
        +findBestNodeForTask(task: ImageTask, nodes: List~Node~) Node
        +balanceWorkload(nodes: List~Node~) LoadBalancingStrategy
    }

    class NodeHealthMonitoringService {
        <<DomainService>>
        +checkNodeHealth(node: Node) NodeHealth
        +markUnhealthyNodes(nodes: List~Node~) void
        +redistributeTasksFromUnhealthyNodes(nodes: List~Node~) void
    }

    class BatchProcessingService {
        <<DomainService>>
        +processBatch(batch: JobBatch) void
        +retryFailedTasks(batch: JobBatch) void
        +calculateBatchProgress(batch: JobBatch) BatchProgress
    }

    %% ===== EVENTOS DE DOMINIO =====
    class UserRegistered {
        <<DomainEvent>>
        -UserId user_id
        -Email email
        -datetime occurred_at
    }

    class NodeRegistered {
        <<DomainEvent>>
        -NodeId node_id
        -NetworkAddress address
        -datetime occurred_at
    }

    class NodeBecameUnhealthy {
        <<DomainEvent>>
        -NodeId node_id
        -string reason
        -datetime occurred_at
    }

    class BatchSubmitted {
        <<DomainEvent>>
        -BatchId batch_id
        -UserId user_id
        -int task_count
        -datetime occurred_at
    }

    class TaskCompleted {
        <<DomainEvent>>
        -TaskId task_id
        -BatchId batch_id
        -NodeId node_id
        -ProcessingResult result
        -datetime occurred_at
    }

    class TaskFailed {
        <<DomainEvent>>
        -TaskId task_id
        -BatchId batch_id
        -ProcessingError error
        -datetime occurred_at
    }

    class BatchCompleted {
        <<DomainEvent>>
        -BatchId batch_id
        -BatchProgress final_progress
        -datetime occurred_at
    }

    %% ===== RELACIONES ENTRE AGREGADOS =====
    User ||--o{ JobBatch : "creates"
    User --> Email : "has"
    User --> UserName : "has"
    User --> UserId : "identified by"

    Node --> NodeId : "identified by"
    Node --> NodeName : "has"
    Node --> NetworkAddress : "located at"
    Node --> NodeStatus : "has"
    Node --> LastHeartbeat : "tracks"

    JobBatch ||--o{ ImageTask : "contains"
    JobBatch --> BatchId : "identified by"
    JobBatch --> UserId : "belongs to"
    JobBatch --> BatchStatus : "has"
    JobBatch --> BatchNote : "has"

    ImageTask --> TaskId : "identified by"
    ImageTask --> BatchId : "belongs to"
    ImageTask --> ImageSpec : "processes"
    ImageTask --> TaskStatus : "has"
    ImageTask --> NodeAssignment : "assigned to"
    ImageTask --> ProcessingResult : "produces"
    ImageTask --> TaskTimestamps : "tracks"

    ImageSpec --> ImageId : "identifies"
    ImageSpec --> TransformationOperation : "applies"

    NodeAssignment --> NodeId : "references"
    ProcessingResult --> ProcessingError : "may have"

    %% ===== SERVICIOS USAN AGREGADOS =====
    TaskDistributionService --> JobBatch : "distributes"
    TaskDistributionService --> Node : "assigns to"
    TaskDistributionService --> ImageTask : "manages"

    NodeHealthMonitoringService --> Node : "monitors"
    NodeHealthMonitoringService --> NodeHealth : "evaluates"

    BatchProcessingService --> JobBatch : "processes"
    BatchProcessingService --> BatchProgress : "calculates"

    %% ===== EVENTOS GENERADOS POR AGREGADOS =====
    User ..|> UserRegistered : "publishes"
    Node ..|> NodeRegistered : "publishes"
    Node ..|> NodeBecameUnhealthy : "publishes"
    JobBatch ..|> BatchSubmitted : "publishes"
    JobBatch ..|> BatchCompleted : "publishes"
    ImageTask ..|> TaskCompleted : "publishes"
    ImageTask ..|> TaskFailed : "publishes"

    %% ===== TIPOS PRIMITIVOS =====
    class CreatedAt {
        <<ValueObject>>
        -datetime value
        +CreatedAt(value: datetime)
        +isOlderThan(duration: Duration) boolean
    }

    class ResultPath {
        <<ValueObject>>
        -string path
        +ResultPath(path: string)
        +exists() boolean
        +getAbsolutePath() string
    }

    class ProcessingLog {
        <<ValueObject>>
        -string message
        -LogLevel level
        +ProcessingLog(message: string, level: LogLevel)
        +toString() string
    }

    ProcessingResult --> ResultPath : "contains"
    ProcessingResult --> ProcessingLog : "contains"
    JobBatch --> CreatedAt : "has"
    TaskTimestamps --> CreatedAt : "extends"
```

## Características del Modelo de Dominio

### Agregados Identificados
1. **User Aggregate**: Gestiona usuarios y sus operaciones
2. **Node Aggregate**: Representa nodos workers y su estado
3. **JobBatch Aggregate**: Coordina lotes de procesamiento de imágenes

### Value Objects
- **Tipos de Identificación**: UserId, NodeId, BatchId, TaskId
- **Datos de Negocio**: Email, NetworkAddress, ImageSpec, ProcessingResult
- **Estados**: NodeStatus, BatchStatus, TaskStatus, NodeHealth

### Servicios de Dominio
- **TaskDistributionService**: Distribuye tareas entre nodos disponibles
- **NodeHealthMonitoringService**: Monitorea la salud de los nodos
- **BatchProcessingService**: Coordina el procesamiento de lotes

### Eventos de Dominio
- Eventos de registro y estado de usuarios y nodos
- Eventos de procesamiento de lotes y tareas
- Permiten reactividad y desacoplamiento

### Invariantes de Dominio
1. Un JobBatch debe tener al menos una ImageTask
2. Una ImageTask solo puede estar asignada a un Node a la vez
3. Un Node debe responder al health check para ser considerado activo
4. Las operaciones de transformación deben ser válidas según el tipo de imagen

### Reglas de Negocio
- Las tareas fallidas pueden ser reintentadas en otros nodos
- Los nodos inactivos no pueden recibir nuevas tareas
- El progreso del lote se calcula basado en el estado de sus tareas
- La distribución de tareas considera la carga actual de los nodos