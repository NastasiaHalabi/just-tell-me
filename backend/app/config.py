from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    database_url: str = "sqlite:///./just_tell_me.db"
    llm_provider: str = ""
    llm_api_key: str = ""
    llm_model: str = ""
    cors_origins: str = "*"


settings = Settings()
