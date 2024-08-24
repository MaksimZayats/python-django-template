FROM python:3.12

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.3.3 /uv /bin/uv

WORKDIR /application

COPY . .

RUN uv sync --frozen
