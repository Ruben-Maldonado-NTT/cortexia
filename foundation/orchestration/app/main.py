import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage, BaseMessage
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg2 import pool
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("cortexia-orchestrator")

app = FastAPI(title="CortexIA Orchestrator", version="0.1.0")

# --- Configuration ---
LITELLM_URL = os.getenv("OPENAI_API_BASE", "http://cortexia-litellm:4000")
LITELLM_KEY = os.getenv("OPENAI_API_KEY", "sk-cortexia-admin-key")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://cortexia:cortexia123@cortexia-postgres:5432/litellm")

# --- Model Setup ---
# We use ChatOpenAI client pointing to LiteLLM
llm = ChatOpenAI(
    base_url=LITELLM_URL,
    api_key=LITELLM_KEY,
    model="local-llama", # Default to valid model in LiteLLM config
    temperature=0
)

# --- State Definition ---
class AgentState(BaseModel):
    messages: List[Dict[str, Any]]

# --- Workflow Definition ---
def agent_node(state: dict):
    logger.info(f"Invoking agent with state: {state}")
    messages = state["messages"]
    # Convert dict messages to LangChain messages for the model
    lc_messages = []
    for m in messages:
        if m["role"] == "user":
            lc_messages.append(HumanMessage(content=m["content"]))
        elif m["role"] == "assistant":
            lc_messages.append(AIMessage(content=m["content"]))
            
    response = llm.invoke(lc_messages)
    return {"messages": [response]} # Append response

# Define Graph
workflow = StateGraph(dict) # Using simple dict state for this v1
workflow.add_node("agent", agent_node)
workflow.set_entry_point("agent")
workflow.add_edge("agent", END)

# Compile Graph (without checkpointer for now to keep v1 simple, we will add PostgresSaver later)
app_graph = workflow.compile()

# --- API Models ---
class RunRequest(BaseModel):
    message: str
    thread_id: Optional[str] = None

class RunResponse(BaseModel):
    response: str
    history: List[Dict[str, str]]

# --- Endpoints ---
@app.get("/health")
def health_check():
    return {"status": "ok", "service": "cortexia-orchestrator"}

@app.post("/run", response_model=RunResponse)
async def run_agent(request: RunRequest):
    try:
        inputs = {"messages": [{"role": "user", "content": request.message}]}
        logger.info(f"Running graph with inputs: {inputs}")
        
        # Invoke the graph
        result = app_graph.invoke(inputs)
        
        # Parse result
        # The result state contains the full history, the last message is the response
        history_messages = result.get("messages", [])
        last_message = history_messages[-1] if history_messages else None
        
        response_content = last_message.content if last_message else "No response generated."
        
        # formatting history for response
        formatted_history = []
        for m in history_messages:
            role = "user" if isinstance(m, HumanMessage) else "assistant"
            # Note: handle plain dict if not using object state yet
            content = m.content if hasattr(m, 'content') else str(m) 
            formatted_history.append({"role": role, "content": content})

        return RunResponse(
            response=response_content,
            history=formatted_history
        )
        
    except Exception as e:
        logger.error(f"Error running agent: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
