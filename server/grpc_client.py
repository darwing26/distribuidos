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
