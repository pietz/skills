---
name: deepchat
description: Build chat interfaces using the Deep Chat web component library connected to a custom backend. Use when creating chat UIs or conversational prototypes.
---

# Quickstart

## Frontend

The frontend is served as static HTML and the chat communication is provided by [DeepChat](https://deepchat.dev/docs/introduction). DeepChat essentially includes a basic but customizable chat UI, but also takes over the communication with your server, if you stick to their data schema.

```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Agentic Chat</title>
  <script type="module" src="https://unpkg.com/deep-chat@2.3.0/dist/deepChat.bundle.js"></script>
</head>

<body style="display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0;">
  <main style="display: flex; align-items: center; justify-content: center; width: 80vw; height: 80vh;">
    <deep-chat connect='{"url": "/chat", "method": "POST", "stream": true}' requestBodyLimits='{"maxMessages": -1}'
      style="border-radius: 10px; width: 100%; height: 100%;"></deep-chat>
  </main>
</body>

</html>
```

## Server

The server sends the static frontend to the user and then serves the one endpoint for interaction. The code below streams the LLM response back to the UI and the rest is taken care of by DeepChat. More advanced agents can be built with Pydantic AI's support for external tools.

```python
import json

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from pydantic_ai import Agent, ModelRequest, ModelResponse, TextPart, UserPromptPart

load_dotenv()

app = FastAPI(title="Agentic Sourcing Prototype")
app.mount("/static", StaticFiles(directory="static"), name="static")
agent = Agent("openai:gpt-5.2", instructions="You're a helpful agent.")

class Message(BaseModel):
    role: str
    text: str | None = None


class Conversation(BaseModel):
    messages: list[Message]

def dc_to_pai(messages: list):
    history = []
    for message in messages:
        if message.role.lower() == "user":
            history.append(ModelRequest(parts=[UserPromptPart(message.text)]))
        else:
            history.append(ModelResponse(parts=[TextPart(message.text)]))
    return history


@app.get("/", response_class=FileResponse)
async def index() -> FileResponse:
    return FileResponse("static/index.html")


@app.post("/chat")
async def chat(request: Conversation) -> StreamingResponse:
    prompt = request.messages[-1].text
    history = dc_to_pai(request.messages[:-1])
    async def generate():
        async with agent.run_stream(prompt, message_history=history) as result:
            async for chunk in result.stream_text(delta=True):
                payload = json.dumps({"text": chunk})
                yield f"data: {payload}\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

## Payloads

### Requests (from Deep Chat)

```json
{
  "messages": [
    {"role": "user", "text": "Hello"},
    {"role": "ai", "text": "Hi there!"},
    {"role": "user", "text": "How are you?"}
  ]
}
```

### Responses (to Deep Chat)

```json
{"text": "I'm doing well, thanks!"}
```
