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
