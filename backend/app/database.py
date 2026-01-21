from dotenv import load_dotenv
load_dotenv()

import os
from sqlmodel import SQLModel, create_engine, Session

# 🔽 IMPORT MODELS (IMPORTANT)
import app.models  # noqa

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(
    DATABASE_URL,
    echo=True,
    pool_pre_ping=True
)

# 🔽 CREATE TABLES ON STARTUP
def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
