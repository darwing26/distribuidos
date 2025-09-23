# Diagrama de Estados UML - Sistema Distribuido de Procesamiento de Imágenes

## 1. Estados del Nodo Worker

```mermaid
stateDiagram-v2
    [*] --> Initializing : Nodo se inicia
    
    Initializing --> Registering : Servicios inicializados
    Registering --> Inactive : Registro fallido
    Registering --> Active : Registro exitoso
    
    Inactive --> Registering : Reintentar registro
    Inactive --> [*] : Apagar nodo
    
    Active --> Processing : Recibe tarea
    Active --> Inactive : Health check falla
    Active --> Maintenance : Señal de mantenimiento
    Active --> [*] : Shutdown graceful
    
    Processing --> Active : Tarea completada exitosamente
    Processing --> Error : Error en procesamiento
    Processing --> Active : Tarea fallida (recuperable)
    
    Error --> Recovering : Intento de recuperación
    Error --> Failed : Error crítico
    
    Recovering --> Active : Recuperación exitosa
    Recovering --> Failed : Recuperación fallida
    
    Failed --> [*] : Apagar nodo
    
    Maintenance --> Active : Mantenimiento completado
    Maintenance --> [*] : Apagar para mantenimiento
    
    state Initializing {
        [*] --> StartingServices
        StartingServices --> LoadingConfig
        LoadingConfig --> InitializingGRPC
        InitializingGRPC --> [*]
    }
    
    state Processing {
        [*] --> ValidatingTask
        ValidatingTask --> ExecutingTransformation
        ExecutingTransformation --> SavingResult
        SavingResult --> [*]
    }
    
    state Recovering {
        [*] --> DiagnosingError
        DiagnosingError --> RestartingServices
        RestartingServices --> TestingConnection
        TestingConnection --> [*]
    }
```

## 2. Estados del Lote de Procesamiento (JobBatch)

```mermaid
stateDiagram-v2
    [*] --> Created : Usuario crea lote
    
    Created --> Validating : Validar datos del lote
    Validating --> Invalid : Validación fallida
    Validating --> Queued : Validación exitosa
    
    Invalid --> [*] : Lote rechazado
    
    Queued --> Distributing : Nodos disponibles
    Queued --> Waiting : No hay nodos disponibles
    
    Waiting --> Distributing : Nodos se vuelven disponibles
    Waiting --> Cancelled : Usuario cancela lote
    
    Distributing --> Processing : Tareas distribuidas
    
    Processing --> Completed : Todas las tareas exitosas
    Processing --> PartiallyFailed : Algunas tareas fallaron
    Processing --> Failed : Todas las tareas fallaron
    Processing --> Cancelled : Usuario cancela lote
    
    PartiallyFailed --> Retrying : Reintentar tareas fallidas
    Retrying --> Processing : Tareas redistribuidas
    Retrying --> PartiallyCompleted : Sin más reintentos
    
    Completed --> Archived : Después de tiempo de retención
    PartiallyCompleted --> Archived : Después de tiempo de retención
    Failed --> Archived : Después de tiempo de retención
    Cancelled --> [*] : Lote eliminado
    
    Archived --> [*] : Limpieza del sistema
    
    state Processing {
        [*] --> TasksExecuting
        TasksExecuting --> MonitoringProgress
        MonitoringProgress --> CalculatingStatus
        CalculatingStatus --> [*]
    }
    
    state Retrying {
        [*] --> IdentifyingFailedTasks
        IdentifyingFailedTasks --> FindingAvailableNodes
        FindingAvailableNodes --> RedistributingTasks
        RedistributingTasks --> [*]
    }
```

## 3. Estados de la Tarea Individual (ImageTask)

```mermaid
stateDiagram-v2
    [*] --> Created : Tarea creada en lote
    
    Created --> Queued : Agregada a cola de procesamiento
    
    Queued --> Assigned : Asignada a nodo worker
    Queued --> Cancelled : Lote cancelado
    
    Assigned --> Processing : Nodo inicia procesamiento
    Assigned --> Reassigning : Nodo no disponible
    
    Reassigning --> Queued : Buscando nuevo nodo
    Reassigning --> Failed : No hay nodos disponibles
    
    Processing --> Completed : Procesamiento exitoso
    Processing --> Failed : Error en procesamiento
    Processing --> Timeout : Tiempo de procesamiento excedido
    
    Timeout --> Retrying : Reintentar en otro nodo
    Failed --> Retrying : Reintentar en otro nodo
    Failed --> PermanentlyFailed : Sin más reintentos
    
    Retrying --> Queued : Reenviar a cola
    Retrying --> PermanentlyFailed : Máximo de reintentos alcanzado
    
    Completed --> Archived : Resultado guardado
    PermanentlyFailed --> Archived : Error documentado
    Cancelled --> Archived : Tarea cancelada
    
    Archived --> [*] : Limpieza del sistema
    
    state Processing {
        [*] --> ValidatingInput
        ValidatingInput --> LoadingImage
        LoadingImage --> ApplyingTransformations
        ApplyingTransformations --> SavingOutput
        SavingOutput --> ReportingResult
        ReportingResult --> [*]
    }
    
    state Retrying {
        [*] --> CheckingRetryCount
        CheckingRetryCount --> FindingAlternateNode : Reintentos disponibles
        CheckingRetryCount --> [*] : Sin reintentos
        FindingAlternateNode --> [*]
    }
```

## 4. Estados del Sistema Distribuido

```mermaid
stateDiagram-v2
    [*] --> Starting : Sistema se inicia
    
    Starting --> Initializing : Componentes básicos listos
    Initializing --> Degraded : Algunos servicios fallan
    Initializing --> Operational : Todos los servicios listos
    
    Degraded --> Operational : Servicios recuperados
    Degraded --> Critical : Servicios críticos fallan
    Degraded --> Maintenance : Mantenimiento programado
    
    Operational --> HighLoad : Carga alta detectada
    Operational --> Degraded : Algunos nodos fallan
    Operational --> Maintenance : Mantenimiento programado
    Operational --> Shutdown : Apagado solicitado
    
    HighLoad --> Operational : Carga normalizada
    HighLoad --> Overloaded : Carga crítica
    HighLoad --> ScalingUp : Escalamiento iniciado
    
    Overloaded --> HighLoad : Carga reducida
    Overloaded --> Critical : Servicios no responden
    
    ScalingUp --> Operational : Nuevos nodos agregados
    ScalingUp --> HighLoad : Escalamiento fallido
    
    Critical --> Recovery : Iniciando recuperación
    Critical --> [*] : Falla catastrófica
    
    Recovery --> Degraded : Recuperación parcial
    Recovery --> Operational : Recuperación completa
    Recovery --> [*] : Recuperación fallida
    
    Maintenance --> Operational : Mantenimiento completado
    Maintenance --> Degraded : Problemas en mantenimiento
    
    Shutdown --> [*] : Sistema apagado
    
    state Starting {
        [*] --> LoadingConfiguration
        LoadingConfiguration --> InitializingDatabase
        InitializingDatabase --> StartingAPIServer
        StartingAPIServer --> [*]
    }
    
    state Operational {
        [*] --> MonitoringNodes
        MonitoringNodes --> ProcessingRequests
        ProcessingRequests --> BalancingLoad
        BalancingLoad --> [*]
    }
    
    state Recovery {
        [*] --> AssessingDamage
        AssessingDamage --> RestartingServices
        RestartingServices --> ValidatingRecovery
        ValidatingRecovery --> [*]
    }
```

## 5. Estados de la Conexión gRPC

```mermaid
stateDiagram-v2
    [*] --> Disconnected : Estado inicial
    
    Disconnected --> Connecting : Iniciar conexión
    
    Connecting --> Connected : Conexión establecida
    Connecting --> Failed : Conexión fallida
    
    Failed --> Disconnected : Timeout alcanzado
    Failed --> Connecting : Reintentar conexión
    
    Connected --> Active : Canal listo para comunicación
    Connected --> Idle : Sin actividad reciente
    Connected --> Disconnected : Conexión perdida
    
    Idle --> Active : Nueva request recibida
    Idle --> Disconnected : Timeout de inactividad
    
    Active --> Idle : Request completada
    Active --> Error : Error en comunicación
    Active --> Disconnected : Conexión cerrada
    
    Error --> Active : Error recuperable
    Error --> Failed : Error crítico
    Error --> Disconnected : Conexión corrupta
    
    state Connecting {
        [*] --> ResolvingAddress
        ResolvingAddress --> EstablishingTCP
        EstablishingTCP --> HandshakingGRPC
        HandshakingGRPC --> [*]
    }
    
    state Active {
        [*] --> SendingRequest
        SendingRequest --> WaitingResponse
        WaitingResponse --> ProcessingResponse
        ProcessingResponse --> [*]
    }
```

## Características de los Diagramas de Estados

### Gestión de Estados Complejos
- **Estados Anidados**: Composición de estados para modelar comportamientos complejos
- **Transiciones Condicionadas**: Cambios de estado basados en condiciones específicas
- **Estados Paralelos**: Múltiples máquinas de estado operando simultáneamente

### Manejo de Errores y Recuperación
- **Estados de Error**: Diferenciación entre errores recuperables y críticos
- **Patrones de Recuperación**: Secuencias definidas para recuperación de fallos
- **Timeout Handling**: Gestión de timeouts en comunicaciones y procesamiento

### Optimización y Performance
- **Estados de Carga**: Diferentes comportamientos según la carga del sistema
- **Escalamiento Dinámico**: Estados que manejan el crecimiento de recursos
- **Balanceo de Carga**: Estados que optimizan la distribución de trabajo

### Persistencia y Limpieza
- **Estados de Archivo**: Gestión del ciclo de vida de datos procesados
- **Limpieza Automática**: Transiciones para liberación de recursos
- **Retención de Datos**: Políticas de mantenimiento de información histórica

### Sincronización y Coordinación
- **Estados de Sincronización**: Coordinación entre componentes distribuidos
- **Estados de Consenso**: Acuerdo entre nodos sobre el estado del sistema
- **Estados de Consistencia**: Mantenimiento de coherencia de datos distribuidos