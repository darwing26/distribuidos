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
