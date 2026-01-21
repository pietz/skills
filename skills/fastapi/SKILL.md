---
name: fastapi
description: A collection of components, patterns, and opinionated best practices when setting up a new FastAPI project or extending an existing one.
---

## Project Structure

```
app.py        # App, lifespan, routes, middleware, templates
models.py     # SQLModel table definitions
config.py     # Settings via pydantic-settings
auth.py       # OAuth and authentication (when needed)
```

Split files at ~250 lines. Add `routers/` when app.py grows.

## Config (config.py)

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    debug: bool = False
    database_url: str = "sqlite:///./app.db"
    secret_key: str = "change-me-in-production"
    base_url: str = "http://localhost:8000"
    # OAuth (add as needed)
    github_client_id: str = ""
    github_client_secret: str = ""

settings = Settings()
```

## Database (models.py)

```python
from contextlib import contextmanager
from typing import Generator
from sqlmodel import SQLModel, Field, Relationship, create_engine, Session
from config import settings

connect_args = {"check_same_thread": False} if "sqlite" in settings.database_url else {}
engine = create_engine(settings.database_url, echo=settings.debug, connect_args=connect_args)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_db() -> Generator[Session, None, None]:
    with Session(engine) as session:
        try:
            yield session
        except Exception:
            session.rollback()
            raise

get_session = contextmanager(get_db)  # For use outside endpoints

class User(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    name: str
    posts: list["Post"] = Relationship(back_populates="user")

class Post(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    title: str
    user: User = Relationship(back_populates="posts")
```

## App (app.py)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, Request
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from sqlmodel import Session, select

from config import settings
from models import init_db, get_db, User

templates = Jinja2Templates(directory="templates")

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=settings.secret_key)

@app.get("/")
async def index(request: Request):
    return templates.TemplateResponse(request, "index.html", {"user": request.session.get("user")})
```

## Authentication (auth.py)

GitHub OAuth pattern with Authlib:

```python
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from authlib.integrations.starlette_client import OAuth
from sqlmodel import Session

from config import settings
from models import get_db, User

router = APIRouter()

oauth = OAuth()
oauth.register(
    name="github",
    client_id=settings.github_client_id,
    client_secret=settings.github_client_secret,
    authorize_url="https://github.com/login/oauth/authorize",
    access_token_url="https://github.com/login/oauth/access_token",
    userinfo_endpoint="https://api.github.com/user",
    client_kwargs={"scope": "user:email"},
)

def authenticate(request: Request) -> str:
    """Dependency for protected endpoints"""
    user_id = request.session.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401)
    return user_id

@router.get("/github/login")
async def github_login(request: Request):
    redirect_url = settings.base_url + "/github/callback"
    return await oauth.github.authorize_redirect(request, redirect_url)

@router.get("/github/callback")
async def github_callback(request: Request, db: Session = Depends(get_db)):
    token = await oauth.github.authorize_access_token(request)
    user_info = await oauth.github.userinfo(token=token)
    user = db.get(User, user_info["id"])
    if not user:
        user = User(id=user_info["id"], email=user_info["email"], name=user_info["name"])
        db.add(user)
        db.commit()
    request.session["user_id"] = user.id
    return RedirectResponse(url="/")

@router.get("/logout")
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/")
```

## Frontend: Jinja2 + HTMX + Bulma

```html
<!-- templates/base.html -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}App{% endblock %}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css">
    <script src="https://unpkg.com/htmx.org@2.0.4"></script>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>
```

Frontend philosophy:
- Use HTMX for interactivity instead of JavaScript frameworks
- Keep logic on the backend, treat frontend as views
- Use Bulma components and utilities for styling
- Only use custom CSS/JS when absolutely necessary

## Email: Brevo + fastapi-mail

```python
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from config import settings

mail_config = ConnectionConfig(
    MAIL_USERNAME=settings.mail_username,
    MAIL_PASSWORD=settings.mail_password,
    MAIL_SERVER=settings.mail_server,
    MAIL_PORT=587,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    MAIL_FROM=settings.mail_from,
    MAIL_FROM_NAME=settings.mail_from_name,
)

async def send_email(recipient: str, subject: str, body: str):
    message = MessageSchema(
        subject=subject,
        recipients=[recipient],
        body=body,
        subtype=MessageType.html,
    )
    await FastMail(mail_config).send_message(message)
```

## CRUD Pattern

```python
@app.post("/users")
def create_user(user: User, session: Session = Depends(get_db)):
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@app.get("/users")
def list_users(session: Session = Depends(get_db)):
    return session.exec(select(User)).all()

@app.get("/users/{user_id}")
def get_user(user_id: int, session: Session = Depends(get_db)):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404)
    return user
```
