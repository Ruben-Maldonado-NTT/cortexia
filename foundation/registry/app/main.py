from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from qdrant_client import QdrantClient
from qdrant_client.http import models
import os

app = FastAPI(title="CortexIA Agent Registry", version="0.1.0")

# Configuration
QDRANT_HOST = os.getenv("QDRANT_HOST", "cortexia-qdrant")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))
COLLECTION_NAME = "agents"

# Clients
# Initialize Qdrant Client - persistent check
try:
    qdrant = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    # Ensure collection exists with named vector for FastEmbed (default model: fast-bge-small-en-v1.5)
    # The default model used by qdrant-client is BAAI/bge-small-en-v1.5
    # We must match the vector name it expects.
    qdrant.recreate_collection(
        collection_name=COLLECTION_NAME,
        vectors_config={
            "fast-bge-small-en-v1.5": models.VectorParams(size=384, distance=models.Distance.COSINE)
        },
        on_disk_payload=True
    )
except Exception as e:
    print(f"Warning: Could not connect to Qdrant or create collection: {e}")
    qdrant = None

# In-memory storage for source of truth
AGENTS_DB: Dict[str, Any] = {}

class AgentInterface(BaseModel):
    input_schema: Dict[str, Any]
    output_schema: Optional[Dict[str, Any]] = None

class AgentSecurity(BaseModel):
    role: Optional[str] = "default"

class Agent(BaseModel):
    id: str = Field(..., pattern="^[a-z0-9-]+$")
    name: str
    version: str = Field(..., pattern=r"^\d+\.\d+\.\d+$")
    description: str
    capabilities: List[str]
    interface: AgentInterface
    security: Optional[AgentSecurity] = None
    owner: Optional[str] = None

class SearchQuery(BaseModel):
    query: str
    limit: int = 5

@app.post("/agents", status_code=201)
def register_agent(agent: Agent):
    if agent.id in AGENTS_DB:
        raise HTTPException(status_code=409, detail="Agent ID already exists")
    
    # store in DB
    AGENTS_DB[agent.id] = agent.dict()
    
    # Index in Qdrant
    if qdrant:
        try:
            # Create a rich text representation for embedding
            text_to_embed = f"{agent.name}: {agent.description}. Capabilities: {', '.join(agent.capabilities)}"
            
            # Using FastEmbed implicitly via Qdrant Client if available, or just raw text if we had a model loaded. 
            # Note: Qdrant Python client 'add' method supports 'documents' which uses FastEmbed automatically!
            qdrant.add(
                collection_name=COLLECTION_NAME,
                documents=[text_to_embed],
                metadata=[{"agent_id": agent.id, "name": agent.name}],
                ids=[hash(agent.id) % ((2**63) - 1)] # Simple deterministic ID for demo
            )
        except Exception as e:
            print(f"Error indexing agent {agent.id}: {e}")
            # We don't fail registration if search indexing fails for now
            
    return {"status": "registered", "agent_id": agent.id}

@app.get("/agents", response_model=List[Agent])
def list_agents():
    return list(AGENTS_DB.values())

@app.get("/agents/{agent_id}", response_model=Agent)
def get_agent(agent_id: str):
    if agent_id not in AGENTS_DB:
        raise HTTPException(status_code=404, detail="Agent not found")
    return AGENTS_DB[agent_id]

@app.post("/search")
def search_agents(query: SearchQuery):
    if not qdrant:
        raise HTTPException(status_code=503, detail="Search service unavailable")
    
    try:
        results = qdrant.query(
            collection_name=COLLECTION_NAME,
            query_text=query.query,
            limit=query.limit
        )
        
        # Hydrate results with full agent details
        agents = []
        for hit in results:
            agent_id = hit.metadata.get("agent_id")
            if agent_id and agent_id in AGENTS_DB:
                agents.append({
                    "agent": AGENTS_DB[agent_id],
                    "score": hit.score
                })
        return {"results": agents}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "ok", "qdrant_connected": qdrant is not None}
