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
