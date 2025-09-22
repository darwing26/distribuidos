import os, sys
CURRENT_DIR = os.path.dirname(__file__)
PROTO_DIR = os.path.join(CURRENT_DIR, "proto")
if PROTO_DIR not in sys.path:
    sys.path.insert(0, PROTO_DIR)
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
