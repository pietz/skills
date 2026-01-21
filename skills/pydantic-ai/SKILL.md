---
name: pydantic-ai
description: Build LLM agents with Pydantic AI. Use when creating AI agents, chatbots, or any LLM-powered functionality with structured inputs/outputs, tool calling, or streaming.
---

## Philosophy: Self-Contained Agents

Build agents as single, shareable Python files. Include the prompt, data models, tools, and agent definition together so the agent works out of the box wherever it's used.

```python
# agents/research_agent.py - Everything in one file
from pydantic import BaseModel
from pydantic_ai import Agent, RunContext

# Output model
class ResearchResult(BaseModel):
    summary: str
    sources: list[str]
    confidence: float

# Agent with instructions
agent = Agent(
    "anthropic:claude-sonnet-4-20250514",
    output_type=ResearchResult,
    instructions="You are a research assistant. Provide well-sourced answers.",
)

# Tools defined alongside agent
@agent.tool
def search_database(ctx: RunContext[str], query: str) -> str:
    """Search the internal database."""
    # Implementation here
    return f"Results for: {query}"
```

## Model Providers

Format: `provider:model-name`. Set API keys via environment variables.

```python
# Common providers
agent = Agent("openai:gpt-4o")           # OPENAI_API_KEY
agent = Agent("anthropic:claude-sonnet-4-20250514")  # ANTHROPIC_API_KEY
agent = Agent("google-gla:gemini-2.0-flash")   # GOOGLE_API_KEY
agent = Agent("groq:llama-3.3-70b")      # GROQ_API_KEY
agent = Agent("ollama:llama3.2")         # Local, no key needed
```

## Running Agents

```python
# Synchronous (simple scripts)
result = agent.run_sync("What is the capital of France?")
print(result.output)

# Async (web apps, concurrent operations)
result = await agent.run("What is the capital of France?")
print(result.output)
```

## Streaming Text

```python
async with agent.run_stream(prompt) as result:
    async for chunk in result.stream_text(delta=True):
        print(chunk, end="", flush=True)
```

For FastAPI/DeepChat integration:

```python
@app.post("/chat")
async def chat(request: ChatRequest):
    prompt = request.messages[-1].text
    history = convert_history(request.messages[:-1])

    async def generate():
        async with agent.run_stream(prompt, message_history=history) as result:
            async for chunk in result.stream_text(delta=True):
                yield f"data: {json.dumps({'text': chunk})}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

## Dependencies (Structured Inputs)

Pass runtime context to agents and tools via `deps_type`:

```python
from dataclasses import dataclass
from pydantic_ai import Agent, RunContext

@dataclass
class UserContext:
    user_id: str
    permissions: list[str]

agent = Agent(
    "openai:gpt-4o",
    deps_type=UserContext,
    instructions="Help the user with their account.",
)

@agent.tool
def get_user_data(ctx: RunContext[UserContext]) -> dict:
    """Fetch user data based on context."""
    return {"user_id": ctx.deps.user_id, "permissions": ctx.deps.permissions}

# Pass deps at runtime
result = agent.run_sync("Show my data", deps=UserContext("u123", ["read", "write"]))
```

## Structured Outputs

```python
from pydantic import BaseModel
from pydantic_ai import Agent

class MovieReview(BaseModel):
    title: str
    rating: float
    summary: str
    recommended: bool

agent = Agent("openai:gpt-4o", output_type=MovieReview)

result = agent.run_sync("Review the movie Inception")
review: MovieReview = result.output
print(f"{review.title}: {review.rating}/10")
```

Streaming structured outputs:

```python
async with agent.run_stream(prompt) as result:
    async for partial in result.stream_output():
        print(partial)  # Partially validated output as it builds
```

## Tool Calling

```python
from pydantic_ai import Agent, RunContext

agent = Agent("openai:gpt-4o", instructions="Help with calculations.")

@agent.tool
def calculate(ctx: RunContext, expression: str) -> float:
    """Evaluate a math expression."""
    return eval(expression)  # Use a safe parser in production

@agent.tool
def get_weather(ctx: RunContext, city: str) -> str:
    """Get current weather for a city."""
    # Call weather API
    return f"Weather in {city}: 22°C, sunny"

result = agent.run_sync("What's 15% of 230, and what's the weather in Paris?")
```

For tools that don't need context:

```python
@agent.tool_plain
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b
```

## MCP Servers

Connect to external MCP servers for additional tools:

```python
from pydantic_ai import Agent
from pydantic_ai.mcp import MCPServerStdio, MCPServerStreamableHTTP

# Stdio-based MCP server (local process)
server = MCPServerStdio("python", args=["mcp_server.py"])

# HTTP-based MCP server (remote)
server = MCPServerStreamableHTTP("http://localhost:8000/mcp")

# Add to agent via toolsets
agent = Agent("openai:gpt-4o", toolsets=[server])

# Use with context manager
async with agent:
    result = await agent.run("Use the MCP tools to help me")
```

## Message History

Maintain conversation context:

```python
from pydantic_ai import Agent
from pydantic_ai.messages import ModelRequest, ModelResponse, UserPromptPart, TextPart

agent = Agent("openai:gpt-4o")

# First message
result1 = await agent.run("My name is Alice")

# Continue with history
result2 = await agent.run("What's my name?", message_history=result1.all_messages())

# Manual history construction
history = [
    ModelRequest(parts=[UserPromptPart(content="Hello")]),
    ModelResponse(parts=[TextPart(content="Hi there!")]),
]
result = await agent.run("Continue our chat", message_history=history)
```

## Complete Self-Contained Example

```python
# agents/support_agent.py
from dataclasses import dataclass
from pydantic import BaseModel
from pydantic_ai import Agent, RunContext

# --- Data Models ---
@dataclass
class CustomerContext:
    customer_id: str
    tier: str  # "free" | "pro" | "enterprise"

class SupportResponse(BaseModel):
    answer: str
    confidence: float
    escalate: bool
    suggested_articles: list[str]

# --- Agent Definition ---
agent = Agent(
    "anthropic:claude-sonnet-4-20250514",
    deps_type=CustomerContext,
    output_type=SupportResponse,
    instructions="""You are a customer support agent.
    - Be helpful and concise
    - Suggest relevant help articles
    - Escalate complex issues (set escalate=True)
    - Consider the customer's tier when answering
    """,
)

# --- Tools ---
@agent.tool
def search_knowledge_base(ctx: RunContext[CustomerContext], query: str) -> list[str]:
    """Search the knowledge base for relevant articles."""
    # Implementation
    return ["article-1", "article-2"]

@agent.tool
def get_account_info(ctx: RunContext[CustomerContext]) -> dict:
    """Get customer account information."""
    return {"id": ctx.deps.customer_id, "tier": ctx.deps.tier}

# --- Usage ---
if __name__ == "__main__":
    customer = CustomerContext("cust_123", "pro")
    result = agent.run_sync("How do I upgrade my plan?", deps=customer)
    print(result.output)
```
