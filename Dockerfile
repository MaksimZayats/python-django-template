FROM python:3.12

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /application

COPY . .

RUN uv sync --frozen
