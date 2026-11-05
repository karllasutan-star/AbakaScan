import asyncio

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database.database import Base, engine
from app.models.classification import ClassificationRecord
from app.models.user import User
from app.routes.admin import router as admin_router
from app.routes.auth import router as auth_router
from app.routes.classifications import router as classifications_router
from app.routes.profile import router as profile_router
from app.services.account_cleanup_service import (
    cleanup_expired_unverified_accounts,
)


async def cleanup_unverified_accounts_loop() -> None:
    while True:
        try:
            with Session(engine) as db:
                deleted_count = (
                    cleanup_expired_unverified_accounts(
                        db,
                    )
                )

                if deleted_count > 0:
                    print(
                        "Deleted "
                        f"{deleted_count} expired "
                        "unverified account(s)."
                    )

        except Exception as error:
            print(
                "Unverified account cleanup failed:",
                error,
            )

        await asyncio.sleep(3600)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)

    # Run cleanup immediately when the backend starts.
    with Session(engine) as db:
        deleted_count = (
            cleanup_expired_unverified_accounts(
                db,
            )
        )

        if deleted_count > 0:
            print(
                "Deleted "
                f"{deleted_count} expired "
                "unverified account(s) "
                "during startup."
            )

    # Continue checking every hour.
    cleanup_task = asyncio.create_task(
        cleanup_unverified_accounts_loop()
    )

    try:
        yield

    finally:
        cleanup_task.cancel()

        try:
            await cleanup_task

        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="ABAKASCAN API",
    description="Backend REST API for ABAKASCAN.",
    version="1.0.0",
    lifespan=lifespan,
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(classifications_router)
app.include_router(admin_router)


@app.get("/")
def root():
    return {
        "message": "ABAKASCAN API is running."
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }

@app.get("/api/status")
def api_status():
    return {
        "status": "online",
        "service": "ABAKASCAN API",
    }


@app.get("/api/database/status")
def database_status():
    try:
        with engine.connect() as connection:
            connection.execute(
                text("SELECT 1")
            )

        return {
            "status": "connected",
            "database": "PostgreSQL",
        }

    except Exception as error:
        return {
            "status": "error",
            "database": "PostgreSQL",
            "message": str(error),
        }