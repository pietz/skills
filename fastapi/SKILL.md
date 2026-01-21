---
name: FastAPI Starter Template
description: A collection of components, patterns, and opinionated best practices when setting up a new FastAPI project or extending an existing one.
---

## Project Structure

```
main.py       # App, lifespan, routes, middleware, templates
models.py     # SQLModel table definitions
config.py     # Settings via pydantic-settings
```

Split files at ~250 lines. Add `routers/` when main.py grows.

## Config (config.py)

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    debug: bool = False
    database_url: str = "sqlite:///./app.db"
    secret_key: str = "change-me-in-production"
    google_client_id: str = ""      # for OAuth
    google_client_secret: str = ""  # for OAuth

settings = Settings()
```

## Database (models.py)

```python
from sqlmodel import SQLModel, Field, create_engine, Session
from config import settings

connect_args = {"check_same_thread": False} if "sqlite" in settings.database_url else {}
engine = create_engine(settings.database_url, echo=settings.debug, connect_args=connect_args)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

class User(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    name: str
```

## App (main.py)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from starlette.requests import Request
from starlette.responses import RedirectResponse
from sqlmodel import Session, select
from authlib.integrations.starlette_client import OAuth

from config import settings
from models import init_db, get_session, User

templates = Jinja2Templates(directory="templates")

oauth = OAuth()
oauth.register(
    name="google",
    client_id=settings.google_client_id,
    client_secret=settings.google_client_secret,
    server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
    client_kwargs={"scope": "openid email profile"},
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=settings.secret_key)

@app.get("/")
async def index(request: Request):
    return templates.TemplateResponse(request, "index.html", {"user": request.session.get("user")})

@app.get("/login")
async def login(request: Request):
    return await oauth.google.authorize_redirect(request, request.url_for("auth_callback"))

@app.get("/auth/callback")
async def auth_callback(request: Request):
    token = await oauth.google.authorize_access_token(request)
    request.session["user"] = dict(token["userinfo"])
    return RedirectResponse(url="/")

@app.get("/logout")
async def logout(request: Request):
    request.session.pop("user", None)
    return RedirectResponse(url="/")
```

## Jinja2 + HTMX

```html
<!-- templates/base.html -->
<!DOCTYPE html>
<html>
<head>
    <script src="https://unpkg.com/htmx.org@2"></script>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>
```

## CRUD Pattern

```python
@app.post("/users")
def create_user(user: User, session: Session = Depends(get_session)):
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@app.get("/users")
def list_users(session: Session = Depends(get_session)):
    return session.exec(select(User)).all()
```
