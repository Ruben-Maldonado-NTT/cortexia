# CortexIA: Developer Guide (DEV)

Welcome to **CortexIA**. This guide walks you through the end-to-end process of creating a Multi-Agent System (MAS) from scratch.

## 🎯 Workflow Overview

1.  **Define Capabilities**: Register tools/skills in the **Agent Registry**.
2.  **Design Logic**: Visually build the agent flow in **Flowise**.
3.  **Deploy Agent**: Expose the flow as an API.
4.  **Integration**: Consume the agent in your applications.

---

## 🚀 Step 1: Define Agent Capabilities (Registry)

Before designing the flow, define *what* your agent can do.

1.  **Access the Registry**: (API Implementation Pending)
    *   Currently configured via `foundation/registry/schemas/agent_schema.json`.
    *   Example Definition:
        ```json
        {
          "name": "FinancialAnalyst",
          "capabilities": ["search_web", "analyze_stock", "generate_report"]
        }
        ```

## 🎨 Step 2: Design Logic (Flowise)

Flowise is the visual canvas for your agents.

1.  **Access Flowise**: [http://flowise.localhost](http://flowise.localhost)
2.  **Create New Chatflow**:
    *   Click **"Add New"**.
    *   Name it (e.g., *SupportBot*).
3.  **Add Nodes**:
    *   **LLM Chain**: Drag **`ChatOllama`**.
    *   **Configuration**:
        | Field           | Value                         | Note                                                 |
        | :-------------- | :---------------------------- | :--------------------------------------------------- |
        | **Base URL**    | `http://litellm.localhost/v1` | **Enterprise Standard**: Access via LiteLLM Ingress. |
        | **Model Name**  | `local-llama`                 | Orchestrated name for `tinyllama`.                   |
        | **Temperature** | `0.7`                         | Adjust for creativity.                               |
    *   **Prompt**: Define the persona (e.g., "You are a helpful assistant").
    *   **Tools**: Connect `Custom Tool` nodes if you registered capabilities.
4.  **Test in Playground**: Use the conversation bubble icon to test prompts and logic.
5.  **Save**: Ensure your flow is saved.

## 🚢 Step 3: Deploy & consume

Once saved, Flowise exposes an API endpoint for your agent.

1.  **Get Endpoint**:
    *   In Flowise, click **"Embed"** or **"API Key"**.
    *   Copy the `API URL` (e.g., `http://cortexia-flowise.cortexia:3000/api/v1/prediction/...`).
2.  **Ingress Access**:
    *   Externally, use: `http://flowise.localhost/api/v1/prediction/...`

## 🔑 Service Credentials

| Service      | Protocol   | Credentials                                |
| :----------- | :--------- | :----------------------------------------- |
| **LiteLLM**  | OpenAI API | `sk-cortexia-admin-key`                    |
| **MinIO**    | S3 API     | `minio` / `minio123`                       |
| **Postgres** | JDBC/SQL   | `cortexia` / `cortexia123` (DB: `flowise`) |
| **Neo4j**    | Bolt/HTTP  | `neo4j` / `cortexia123`                    |

## 🧩 Step 4: Front-end Integration (Backstage)

Register your new service in the Developer Portal.

1.  **Access Backstage**: [http://backstage.localhost](http://backstage.localhost)
2.  **Create Component**:
    *   Select **"Create..."**.
    *   Choose a template (e.g., *Agent Service*).
    *   Link to your Flowise API and Git repo.

## 🛠 Troubleshooting

*   **Agent fails to reply?**: Check **LiteLLM** status (`kubectl logs -l app=cortexia-litellm`).
*   **Tools not working?**: Verify **Orchestrator** connectivity.
