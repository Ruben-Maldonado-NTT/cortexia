import os
import requests
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from mcp.server import Server
from mcp.server.sse import SseServerTransport
from mcp.types import Tool, TextContent, ImageContent, EmbeddedResource

app = FastAPI(title="CortexIA MCP Gateway")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OPA configuration
OPA_URL = os.getenv("OPA_URL", "http://cortexia-opa:8181/v1/data/mcp/rbac/allow")

async def check_permissions(user: str, role: str, action: str, tool_name: str = None):
    try:
        payload = {
            "input": {
                "user": user,
                "role": role,
                "action": action,
                "tool": tool_name
            }
        }
        # In a real scenario, use an async client
        response = requests.post(OPA_URL, json=payload, timeout=2)
        result = response.json().get("result", False)
        return result
    except Exception as e:
        print(f"Error connecting to OPA: {e}")
        return False

# Initialize MCP Server
mcp_server = Server("cortexia-gateway")

@mcp_server.list_tools()
async def list_tools():
    return [
        Tool(
            name="get_weather",
            description="Get the current weather in a location",
            inputSchema={
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                },
                "required": ["location"]
            }
        ),
        Tool(
            name="search_registry",
            description="Search for agents in the registry",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                },
                "required": ["query"]
            }
        )
    ]

@mcp_server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "get_weather":
        return [TextContent(type="text", text=f"The weather in {arguments['location']} is sunny.")]
    elif name == "search_registry":
        return [TextContent(type="text", text=f"Searching registry for: {arguments['query']}... (Access Granted)")]
    else:
        raise ValueError(f"Unknown tool: {name}")

sse = SseServerTransport("/mcp/messages")

@app.get("/mcp/sse")
async def sse_endpoint(request: Request):
    async with sse.connect_sse(request.scope, request.receive, request._send) as (read_stream, write_stream):
        await mcp_server.run(read_stream, write_stream, mcp_server.create_initialization_options())

@app.post("/mcp/messages")
async def messages_endpoint(request: Request):
    return await sse.handle_post_message(request.scope, request.receive, request._send)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "cortexia-mcp-gateway"}

@app.get("/secure-tools")
async def get_secure_tools(user: str = "viewer", role: str = "viewer"):
    if await check_permissions(user, role, "read_tools"):
        return {"tools": ["get_weather", "search_registry"]}
    raise HTTPException(status_code=403, detail="Unauthorized")
