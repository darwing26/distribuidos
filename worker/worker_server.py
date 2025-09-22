import os, sys
# añade la carpeta 'worker/proto' al path para que worker_pb2 sea importable
CURRENT_DIR = os.path.dirname(__file__)
PROTO_DIR = os.path.join(CURRENT_DIR, "proto")
if PROTO_DIR not in sys.path:
    sys.path.insert(0, PROTO_DIR)
import time
from concurrent import futures
import grpc
from worker.proto import worker_pb2, worker_pb2_grpc

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
