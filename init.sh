#!/usr/bin/env bash
set -e

# Proyecto base
PROJECT_ROOT="$(pwd)"
echo "Project root: $PROJECT_ROOT"

# 1) Crear venv
if [ ! -d ".venv" ]; then
  python -m venv .venv
fi
# Activar venv (Bash)
source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate

# 2) requirements
cat > requirements.txt << 'REQ'
fastapi==0.115.2
uvicorn[standard]==0.30.6
sqlmodel==0.0.22
pydantic==2.9.2
grpcio==1.66.1
grpcio-tools==1.66.1
python-multipart==0.0.12
REQ

pip install --upgrade pip
pip install -r requirements.txt

# 3) Estructura carpetas
mkdir -p server/proto worker/proto

# 4) Proto compartido
cat > server/proto/worker.proto << 'PROTO'
syntax = "proto3";
package worker;

message HealthRequest {}
message HealthReply { string status = 1; }

message TransformTask {
  string request_id = 1;
  string image_id   = 2;
  string operation  = 3; // e.g., "grayscale", "resize:800x600"
}

message TransformReply {
  string request_id = 1;
  string image_id   = 2;
  string status     = 3; // "OK" | "ERROR"
  string result_path = 4; // dummy for avance 2
  string log_message = 5;
}

service WorkerService {
  rpc Health(HealthRequest) returns (HealthReply);
  rpc SubmitTask(TransformTask) returns (TransformReply);
}
PROTO

cp server/proto/worker.proto worker/proto/worker.proto

# 5) Generador de stubs
cat > server/proto/build_stubs.py << 'PY'
import os
from grpc_tools import protoc

HERE = os.path.dirname(__file__)
proto = os.path.join(HERE, "worker.proto")
out  = HERE

protoc.main([
    "protoc",
    f"-I{HERE}",
    f"--python_out={out}",
    f"--grpc_python_out={out}",
    proto
])

print("gRPC stubs generated in", out)
PY

cp server/proto/build_stubs.py worker/proto/build_stubs.py

# 6) Código del servidor FastAPI
cat > server/db.py << 'PY'
from sqlmodel import SQLModel, Field, Session, create_engine, select
from typing import Optional
from datetime import datetime

DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(DATABASE_URL, echo=False)

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str
    name: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Node(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    host: str
    port: int
    status: str = "inactive"  # active | inactive | error
    last_heartbeat: Optional[datetime] = None

class JobBatch(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = "queued"    # queued|processing|done|error
    note: Optional[str] = None

class ImageTask(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    batch_id: int
    image_id: str
    transformations: str
    received_at: datetime = Field(default_factory=datetime.utcnow)
    processed_at: Optional[datetime] = None
    node_id: Optional[int] = None
    result_path: Optional[str] = None
    status: str = "queued"    # queued|processing|done|error
    log: Optional[str] = None

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    return Session(engine)
PY

cat > server/schemas.py << 'PY'
from pydantic import BaseModel
from typing import List, Optional

class SignupRequest(BaseModel):
    email: str
    name: str

class LoginRequest(BaseModel):
    email: str

class NodeRegister(BaseModel):
    name: str
    host: str
    port: int

class NodeOut(BaseModel):
    id: int
    name: str
    host: str
    port: int
    status: str

class TransformDef(BaseModel):
    # ejemplo: {"image_id":"img1","operations":["grayscale","resize:800x600"]}
    image_id: str
    operations: List[str]

class BatchSubmit(BaseModel):
    user_id: int
    images: List[TransformDef]
    note: Optional[str] = None

class BatchOut(BaseModel):
    batch_id: int
    status: str
PY

cat > server/grpc_client.py << 'PY'
import grpc
from typing import Tuple
from dataclasses import dataclass
from .proto import worker_pb2, worker_pb2_grpc

@dataclass
class NodeAddr:
    host: str
    port: int

def health_check(node: NodeAddr) -> str:
    with grpc.insecure_channel(f"{node.host}:{node.port}") as channel:
        stub = worker_pb2_grpc.WorkerServiceStub(channel)
        reply = stub.Health(worker_pb2.HealthRequest())
        return reply.status

def submit_task(node: NodeAddr, request_id: str, image_id: str, operation: str):
    with grpc.insecure_channel(f"{node.host}:{node.port}") as channel:
        stub = worker_pb2_grpc.WorkerServiceStub(channel)
        reply = stub.SubmitTask(worker_pb2.TransformTask(
            request_id=request_id, image_id=image_id, operation=operation
        ))
        return reply
PY

cat > server/main.py << 'PY'
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from datetime import datetime
from .db import init_db, get_session, User, Node, JobBatch, ImageTask
from .schemas import SignupRequest, LoginRequest, NodeRegister, NodeOut, BatchSubmit, BatchOut
from .grpc_client import NodeAddr, health_check, submit_task
from sqlmodel import select

app = FastAPI(title="Imagenes Distribuido - Avance 2", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

@app.on_event("startup")
def startup():
    init_db()

# ---------- Auth dummy ----------
@app.post("/auth/signup")
def signup(req: SignupRequest):
    with get_session() as s:
        user = User(email=req.email, name=req.name)
        s.add(user); s.commit(); s.refresh(user)
        return {"user_id": user.id, "message": "signup ok (dummy)"}

@app.post("/auth/login")
def login(req: LoginRequest):
    # Avance 2: sin verificación real
    with get_session() as s:
        user = s.exec(select(User).where(User.email == req.email)).first()
        if not user:
            return {"ok": False, "message": "User not found"}
        return {"ok": True, "user_id": user.id, "token": "dummy-token"}

# ---------- NodOS ----------
@app.post("/nodes/register", response_model=NodeOut)
def register_node(req: NodeRegister):
    with get_session() as s:
        node = Node(name=req.name, host=req.host, port=req.port, status="inactive")
        s.add(node); s.commit(); s.refresh(node)
        return NodeOut(id=node.id, name=node.name, host=node.host, port=node.port, status=node.status)

@app.get("/nodes", response_model=List[NodeOut])
def list_nodes():
    with get_session() as s:
        nodes = s.exec(select(Node)).all()
        return [NodeOut(id=n.id, name=n.name, host=n.host, port=n.port, status=n.status) for n in nodes]

@app.post("/nodes/{node_id}/ping")
def ping_node(node_id:int):
    with get_session() as s:
        node = s.get(Node, node_id)
        if not node: return {"ok": False, "message": "node not found"}
        status = "error"
        try:
            status = health_check(NodeAddr(host=node.host, port=node.port))
        except Exception as e:
            status = "error"
        node.status = "active" if status=="OK" else "error"
        node.last_heartbeat = datetime.utcnow()
        s.add(node); s.commit()
        return {"node_id": node.id, "status": node.status}

# ---------- Batches (dummy) ----------
@app.post("/batches/submit", response_model=BatchOut)
def submit_batch(req: BatchSubmit):
    with get_session() as s:
        batch = JobBatch(user_id=req.user_id, status="processing", note=req.note)
        s.add(batch); s.commit(); s.refresh(batch)
        # Insertar tareas
        for img in req.images:
            it = ImageTask(batch_id=batch.id, image_id=img.image_id, transformations="|".join(img.operations), status="queued")
            s.add(it)
        s.commit()
        return BatchOut(batch_id=batch.id, status=batch.status)

@app.get("/batches/{batch_id}/status")
def batch_status(batch_id:int):
    with get_session() as s:
        batch = s.get(JobBatch, batch_id)
        if not batch: return {"ok": False, "message": "batch not found"}
        tasks = s.exec(select(ImageTask).where(ImageTask.batch_id==batch_id)).all()
        return {
            "batch_id": batch_id,
            "status": batch.status,
            "tasks": [
                {"image_id": t.image_id, "status": t.status, "node_id": t.node_id, "result_path": t.result_path}
                for t in tasks
            ]
        }

# Endpoint para simular el envío de una operación simple a un nodo (prueba gRPC)
@app.post("/batches/{batch_id}/dispatch_test/{node_id}")
def dispatch_test(batch_id:int, node_id:int):
    with get_session() as s:
        node = s.get(Node, node_id)
        if not node: return {"ok": False, "message": "node not found"}
        # tomar una task
        task = s.exec(select(ImageTask).where(ImageTask.batch_id==batch_id).limit(1)).first()
        if not task: return {"ok": False, "message": "no tasks"}
        try:
            rep = submit_task(NodeAddr(node.host, node.port), request_id=str(batch_id), image_id=task.image_id, operation="grayscale")
            task.status = "done" if rep.status=="OK" else "error"
            task.node_id = node.id
            task.result_path = rep.result_path
            task.log = rep.log_message
            s.add(task); s.commit()
            return {"ok": True, "worker_reply": {"status": rep.status, "result_path": rep.result_path}}
        except Exception as e:
            task.status="error"; s.add(task); s.commit()
            return {"ok": False, "message": str(e)}

# Subida de archivos (por ahora no se guardan físicamente; demo)
@app.post("/files/upload")
async def upload_files(files: List[UploadFile] = File(...)):
    names = [f.filename for f in files]
    return {"received": names}
PY

# 7) Worker gRPC (dummy)
cat > worker/worker_server.py << 'PY'
import time
from concurrent import futures
import grpc
from proto import worker_pb2, worker_pb2_grpc

class WorkerService(worker_pb2_grpc.WorkerServiceServicer):
    def Health(self, request, context):
        return worker_pb2.HealthReply(status="OK")

    def SubmitTask(self, request, context):
        # Simulación de trabajo
        time.sleep(0.5)
        return worker_pb2.TransformReply(
            request_id=request.request_id,
            image_id=request.image_id,
            status="OK",
            result_path=f"/results/{request.image_id}_dummy.png",
            log_message=f"Simulated op: {request.operation}"
        )

def serve(port: int = 50051):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    worker_pb2_grpc.add_WorkerServiceServicer_to_server(WorkerService(), server)
    server.add_insecure_port(f"[::]:{port}")
    server.start()
    print(f"Worker gRPC running on {port}")
    server.wait_for_termination()

if __name__ == "__main__":
    serve()
PY

# 8) __init__.py for relative imports
echo "" > server/__init__.py
echo "" > worker/__init__.py

# 9) Generar stubs
python server/proto/build_stubs.py
python worker/proto/build_stubs.py

echo "--------------------------------------"
echo "Instalación completa."
echo "Comandos recomendados:"
echo "1) Activar venv: source .venv/Scripts/activate (Windows Git Bash) o .venv\\Scripts\\activate en PowerShell"
echo "2) Levantar worker: python -m worker.worker_server"
echo "3) Levantar server: uvicorn server.main:app --reload"
echo "Abrir Swagger: http://127.0.0.1:8000/docs"