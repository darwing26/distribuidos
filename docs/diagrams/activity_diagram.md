# Diagrama de Actividades UML - Flujos de Procesos del Sistema Distribuido

## 1. Flujo de Procesamiento de Lote de Imágenes

```mermaid
flowchart TD
    Start([Inicio: Usuario quiere procesar imágenes]) --> Login{¿Usuario autenticado?}
    
    Login -->|No| DoLogin[Iniciar sesión]
    DoLogin --> Login
    
    Login -->|Sí| UploadFiles[Subir archivos de imagen]
    UploadFiles --> ValidateFiles{¿Archivos válidos?}
    
    ValidateFiles -->|No| ShowUploadError[Mostrar error de validación]
    ShowUploadError --> UploadFiles
    
    ValidateFiles -->|Sí| DefineTransformations[Definir transformaciones para cada imagen]
    DefineTransformations --> CreateBatch[Crear lote de procesamiento]
    
    CreateBatch --> StoreBatch[(Guardar lote en BD)]
    StoreBatch --> CreateTasks[Crear tareas individuales]
    
    CreateTasks --> CheckAvailableNodes{¿Hay nodos disponibles?}
    
    CheckAvailableNodes -->|No| WaitForNodes[Esperar nodos disponibles]
    WaitForNodes --> CheckAvailableNodes
    
    CheckAvailableNodes -->|Sí| DistributeTasks[Distribuir tareas a nodos]
    
    DistributeTasks --> ParallelProcessing{Procesamiento paralelo}
    
    %% Rama de procesamiento individual
    ParallelProcessing --> ProcessTask[Procesar tarea en nodo worker]
    ProcessTask --> TaskSuccess{¿Procesamiento exitoso?}
    
    TaskSuccess -->|No| RetryTask{¿Reintentos disponibles?}
    RetryTask -->|Sí| FindOtherNode[Buscar otro nodo disponible]
    FindOtherNode --> ProcessTask
    RetryTask -->|No| MarkTaskFailed[Marcar tarea como fallida]
    
    TaskSuccess -->|Sí| SaveResult[Guardar resultado]
    SaveResult --> UpdateTaskStatus[Actualizar estado de tarea]
    
    MarkTaskFailed --> UpdateTaskStatus
    UpdateTaskStatus --> CheckBatchComplete{¿Todas las tareas completadas?}
    
    CheckBatchComplete -->|No| ParallelProcessing
    CheckBatchComplete -->|Sí| CalculateProgress[Calcular progreso final del lote]
    
    CalculateProgress --> NotifyUser[Notificar al usuario]
    NotifyUser --> End([Fin: Lote procesado])
    
    %% Estilos
    classDef startEnd fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef process fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef error fill:#ffebee,stroke:#f44336,stroke-width:2px
    classDef storage fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    
    class Start,End startEnd
    class DoLogin,UploadFiles,DefineTransformations,CreateBatch,CreateTasks,DistributeTasks,ProcessTask,SaveResult,UpdateTaskStatus,CalculateProgress,NotifyUser,FindOtherNode process
    class Login,ValidateFiles,CheckAvailableNodes,TaskSuccess,RetryTask,CheckBatchComplete decision
    class ShowUploadError,MarkTaskFailed,WaitForNodes error
    class StoreBatch storage
```

## 2. Flujo de Registro y Monitoreo de Nodos

```mermaid
flowchart TD
    StartNode([Inicio: Nodo worker se inicia]) --> InitializeNode[Inicializar servicios del nodo]
    
    InitializeNode --> StartGRPCServer[Iniciar servidor gRPC]
    StartGRPCServer --> RegisterWithMaster[Registrarse con el servidor principal]
    
    RegisterWithMaster --> RegistrationSuccess{¿Registro exitoso?}
    
    RegistrationSuccess -->|No| WaitAndRetry[Esperar y reintentar registro]
    WaitAndRetry --> RegisterWithMaster
    
    RegistrationSuccess -->|Sí| UpdateNodeStatus[Actualizar estado a 'activo']
    UpdateNodeStatus --> StartHeartbeat[Iniciar heartbeat periódico]
    
    StartHeartbeat --> NodeActiveLoop{Bucle de nodo activo}
    
    %% Bucle principal del nodo
    NodeActiveLoop --> WaitForTasks[Esperar tareas del servidor]
    WaitForTasks --> TaskReceived{¿Tarea recibida?}
    
    TaskReceived -->|No| HealthCheck[Responder health check]
    HealthCheck --> NodeActiveLoop
    
    TaskReceived -->|Sí| ValidateTask{¿Tarea válida?}
    
    ValidateTask -->|No| SendErrorResponse[Enviar respuesta de error]
    SendErrorResponse --> NodeActiveLoop
    
    ValidateTask -->|Sí| ProcessImageTask[Procesar transformación de imagen]
    ProcessImageTask --> TaskProcessingResult{¿Procesamiento exitoso?}
    
    TaskProcessingResult -->|No| LogError[Registrar error en log]
    LogError --> SendFailureResponse[Enviar respuesta de fallo]
    SendFailureResponse --> NodeActiveLoop
    
    TaskProcessingResult -->|Sí| SaveProcessedImage[Guardar imagen procesada]
    SaveProcessedImage --> SendSuccessResponse[Enviar respuesta exitosa]
    SendSuccessResponse --> NodeActiveLoop
    
    %% Gestión de errores y shutdown
    NodeActiveLoop --> NodeError{¿Error crítico?}
    NodeError -->|Sí| LogCriticalError[Registrar error crítico]
    LogCriticalError --> UpdateStatusError[Actualizar estado a 'error']
    UpdateStatusError --> AttemptRecovery[Intentar recuperación]
    
    AttemptRecovery --> RecoverySuccess{¿Recuperación exitosa?}
    RecoverySuccess -->|Sí| UpdateNodeStatus
    RecoverySuccess -->|No| Shutdown[Apagar nodo gracefully]
    
    NodeError -->|No| ShutdownSignal{¿Señal de apagado?}
    ShutdownSignal -->|No| NodeActiveLoop
    ShutdownSignal -->|Sí| Shutdown
    
    Shutdown --> UnregisterNode[Desregistrar del servidor principal]
    UnregisterNode --> StopServices[Detener servicios]
    StopServices --> EndNode([Fin: Nodo apagado])
    
    %% Estilos
    classDef startEnd fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef process fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef error fill:#ffebee,stroke:#f44336,stroke-width:2px
    classDef loop fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    
    class StartNode,EndNode startEnd
    class InitializeNode,StartGRPCServer,RegisterWithMaster,UpdateNodeStatus,StartHeartbeat,WaitForTasks,ProcessImageTask,SaveProcessedImage,SendSuccessResponse,LogError,SendFailureResponse,SendErrorResponse,LogCriticalError,UpdateStatusError,AttemptRecovery,Shutdown,UnregisterNode,StopServices process
    class RegistrationSuccess,TaskReceived,ValidateTask,TaskProcessingResult,NodeError,RecoverySuccess,ShutdownSignal decision
    class WaitAndRetry,HealthCheck error
    class NodeActiveLoop loop
```

## 3. Flujo de Monitoreo del Sistema

```mermaid
flowchart TD
    StartMonitoring([Inicio: Sistema de monitoreo]) --> InitializeMonitor[Inicializar monitor del sistema]
    
    InitializeMonitor --> LoadConfiguration[Cargar configuración de monitoreo]
    LoadConfiguration --> StartMonitoringLoop[Iniciar bucle de monitoreo]
    
    StartMonitoringLoop --> MonitoringCycle{Ciclo de monitoreo}
    
    MonitoringCycle --> CheckAllNodes[Verificar estado de todos los nodos]
    CheckAllNodes --> PerformHealthChecks[Realizar health checks]
    
    PerformHealthChecks --> AnalyzeResults[Analizar resultados]
    AnalyzeResults --> IdentifyUnhealthyNodes{¿Hay nodos no saludables?}
    
    IdentifyUnhealthyNodes -->|Sí| MarkNodesUnhealthy[Marcar nodos como no saludables]
    MarkNodesUnhealthy --> ReallocateTasks[Reasignar tareas de nodos no saludables]
    ReallocateTasks --> SendAlerts[Enviar alertas a administradores]
    
    IdentifyUnhealthyNodes -->|No| UpdateMetrics[Actualizar métricas del sistema]
    SendAlerts --> UpdateMetrics
    
    UpdateMetrics --> CheckSystemLoad[Verificar carga del sistema]
    CheckSystemLoad --> AnalyzePerformance[Analizar rendimiento]
    
    AnalyzePerformance --> OptimizeDistribution{¿Optimización necesaria?}
    
    OptimizeDistribution -->|Sí| RebalanceWorkload[Rebalancear carga de trabajo]
    RebalanceWorkload --> UpdateLoadBalancer[Actualizar estrategia de balanceo]
    UpdateLoadBalancer --> LogOptimization[Registrar optimización realizada]
    
    OptimizeDistribution -->|No| CheckBatchProgress[Verificar progreso de lotes]
    LogOptimization --> CheckBatchProgress
    
    CheckBatchProgress --> UpdateBatchStatuses[Actualizar estados de lotes]
    UpdateBatchStatuses --> GenerateReports[Generar reportes de estado]
    
    GenerateReports --> WaitMonitoringInterval[Esperar intervalo de monitoreo]
    WaitMonitoringInterval --> MonitoringCycle
    
    MonitoringCycle --> StopSignal{¿Señal de parada?}
    StopSignal -->|No| MonitoringCycle
    StopSignal -->|Sí| CleanupMonitoring[Limpiar recursos de monitoreo]
    
    CleanupMonitoring --> SaveFinalReports[Guardar reportes finales]
    SaveFinalReports --> EndMonitoring([Fin: Monitoreo detenido])
    
    %% Estilos
    classDef startEnd fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    classDef process fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef optimization fill:#e8f5e8,stroke:#8bc34a,stroke-width:2px
    classDef alert fill:#ffebee,stroke:#f44336,stroke-width:2px
    
    class StartMonitoring,EndMonitoring startEnd
    class InitializeMonitor,LoadConfiguration,StartMonitoringLoop,CheckAllNodes,PerformHealthChecks,AnalyzeResults,UpdateMetrics,CheckSystemLoad,AnalyzePerformance,CheckBatchProgress,UpdateBatchStatuses,GenerateReports,WaitMonitoringInterval,CleanupMonitoring,SaveFinalReports process
    class MonitoringCycle,IdentifyUnhealthyNodes,OptimizeDistribution,StopSignal decision
    class RebalanceWorkload,UpdateLoadBalancer,LogOptimization optimization
    class MarkNodesUnhealthy,ReallocateTasks,SendAlerts alert
```

## Características de los Flujos de Actividades

### Concurrencia y Paralelismo
- **Procesamiento Paralelo**: Las tareas se procesan simultáneamente en múltiples nodos
- **Monitoreo Asíncrono**: El sistema de monitoreo opera independientemente del procesamiento
- **Heartbeats Independientes**: Cada nodo mantiene su propio ciclo de vida

### Manejo de Errores y Recuperación
- **Reintentos Automáticos**: Tareas fallidas se reintientan en otros nodos
- **Recuperación Graceful**: Los nodos intentan recuperarse de errores antes de apagarse
- **Reasignación Dinámica**: Las tareas se redistribuyen cuando los nodos fallan

### Optimización y Balanceo
- **Distribución Inteligente**: Las tareas se asignan considerando la carga de los nodos
- **Rebalanceo Dinámico**: El sistema ajusta la distribución según el rendimiento
- **Monitoreo Continuo**: Supervisión constante para optimizar recursos

### Estados y Transiciones
- **Estados de Nodos**: activo, inactivo, error, recuperándose
- **Estados de Tareas**: en cola, procesando, completada, fallida
- **Estados de Lotes**: en cola, procesando, completado, parcialmente fallido

### Puntos de Sincronización
- **Finalización de Lotes**: Espera a que todas las tareas se completen
- **Health Checks**: Sincronización periódica del estado de nodos
- **Reportes de Estado**: Generación coordinada de métricas del sistema