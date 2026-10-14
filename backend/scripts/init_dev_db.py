"""Create tables for development only; production requires reviewed migrations."""
from app.main import Base, engine, settings

if __name__ == "__main__":
    if settings.environment != "development":
        raise SystemExit("Refusing to create clinical schema outside development")
    Base.metadata.create_all(bind=engine)
    print("Development tables initialized. Use synthetic records only.")
