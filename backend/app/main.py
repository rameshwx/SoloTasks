from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.auth.router import router as auth_router
from app.core.config import get_settings
from app.modules.attachments.router import router as attachments_router
from app.modules.export_import.router import router as export_import_router
from app.modules.holidays.router import router as holidays_router
from app.modules.reminders.router import router as reminders_router
from app.modules.smart_lists.router import router as smart_lists_router
from app.modules.subtasks.router import router as subtasks_router
from app.modules.tags.router import router as tags_router
from app.modules.tasks.router import router as tasks_router
from app.modules.user_settings.router import router as user_settings_router
from app.sync.router import router as sync_router

settings = get_settings()

app = FastAPI(title=settings.app_name, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api = settings.api_prefix
app.include_router(auth_router, prefix=api)
app.include_router(sync_router, prefix=api)
app.include_router(tags_router, prefix=api)
app.include_router(tasks_router, prefix=api)
app.include_router(subtasks_router, prefix=api)
app.include_router(reminders_router, prefix=api)
app.include_router(attachments_router, prefix=api)
app.include_router(holidays_router, prefix=api)
app.include_router(smart_lists_router, prefix=api)
app.include_router(export_import_router, prefix=api)
app.include_router(user_settings_router, prefix=api)


@app.get("/health")
def health():
    return {"status": "ok"}
