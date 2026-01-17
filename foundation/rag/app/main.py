import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

from haystack import Pipeline, Document
from haystack.components.embedders import OpenAITextEmbedder, OpenAIDocumentEmbedder
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.builders import PromptBuilder
from haystack.components.generators import OpenAIGenerator
# from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
# from haystack_integrations.components.retrievers.qdrant import QdrantEmbeddingRetriever

# Note: For this initial v1 implementation to be robust without dependent service failures,
# we will use InMemoryDocumentStore temporarily if Qdrant connection is complex to init synchronously,
# BUT the goal is Qdrant. Let's try Qdrant first.
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
from haystack_integrations.components.retrievers.qdrant import QdrantEmbeddingRetriever
from haystack.components.writers import DocumentWriter
from haystack.utils import Secret

app = FastAPI(title="CortexIA RAG Service", version="0.1.0")

# --- Configuration ---
QDRANT_URL = os.getenv("QDRANT_URL", "http://cortexia-qdrant:6333")
OPENAI_API_BASE = os.getenv("OPENAI_API_BASE", "http://cortexia-litellm:4000")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "sk-cortexia-admin-key")
EMBEDDING_MODEL = "local-llama" # Using Ollama via LiteLLM
LLM_MODEL = "local-llama"

# --- Document Store ---
# Using "documents" collection in Qdrant
document_store = QdrantDocumentStore(
    url=QDRANT_URL,
    index="documents",
    return_embedding=True,
    wait_result_from_api=True
)

# --- Pipelines ---

# 1. Indexing Pipeline
indexing_pipeline = Pipeline()
indexing_pipeline.add_component("embedder", OpenAIDocumentEmbedder(
    api_key=Secret.from_token(OPENAI_API_KEY),
    model=EMBEDDING_MODEL,
    api_base_url=OPENAI_API_BASE
))
indexing_pipeline.add_component("writer", DocumentWriter(document_store=document_store))
indexing_pipeline.connect("embedder", "writer")

# 2. RAG (Query) Pipeline
template = """
Answer the question based on the context below.

Context:
{% for document in documents %}
    {{ document.content }}
{% endfor %}

Question: {{ question }}
Answer:
"""
rag_pipeline = Pipeline()
rag_pipeline.add_component("embedder", OpenAITextEmbedder(
    api_key=Secret.from_token(OPENAI_API_KEY),
    model=EMBEDDING_MODEL,
    api_base_url=OPENAI_API_BASE
))
rag_pipeline.add_component("retriever", QdrantEmbeddingRetriever(document_store=document_store))
rag_pipeline.add_component("prompt_builder", PromptBuilder(template=template))
rag_pipeline.add_component("llm", OpenAIGenerator(
    api_key=Secret.from_token(OPENAI_API_KEY),
    model=LLM_MODEL,
    api_base_url=OPENAI_API_BASE
))

rag_pipeline.connect("embedder.embedding", "retriever.query_embedding")
rag_pipeline.connect("retriever", "prompt_builder.documents")
rag_pipeline.connect("prompt_builder", "llm")

# --- API Models ---
class IndexRequest(BaseModel):
    documents: List[str]

class QueryRequest(BaseModel):
    question: str

class QueryResponse(BaseModel):
    answer: str
    context: List[str]

# --- Endpoints ---
@app.get("/health")
def health_check():
    return {"status": "ok", "service": "cortexia-rag"}

@app.post("/index")
def index_documents(request: IndexRequest):
    docs = [Document(content=d) for d in request.documents]
    indexing_pipeline.run({"embedder": {"documents": docs}})
    return {"status": "indexed", "count": len(docs)}

@app.post("/query", response_model=QueryResponse)
def query(request: QueryRequest):
    result = rag_pipeline.run({
        "embedder": {"text": request.question},
        "prompt_builder": {"question": request.question}
    })
    
    answer = result["llm"]["replies"][0]
    # Extract context from retriever result (not directly in final output unless returned)
    # We'd need to capture it, but for now retrieving valid answer is enough
    return QueryResponse(answer=answer, context=[])

