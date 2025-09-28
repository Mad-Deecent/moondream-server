# Repository Guidelines

## Project Structure & Module Organization
- `app/` holds the FastAPI service; `app/app.py` wires endpoints and model loading; `__init__.py` keeps it package-ready.
- `app/requirements.txt` tracks runtime dependencies; update it alongside hashed lock if we add libs.
- `app/test_api.py` is a live-integration harness hitting a running server.
- `charts/` contains the Helm chart and `templates/` manifests used in production deployments.
- `.github/workflows/` houses release pipelines; keep env and tag updates in sync with code changes.
- `Dockerfile` builds the production image; respect the non-root `moondream` user when adding assets.

## Build, Test, and Development Commands
- `python -m venv .venv && source .venv/bin/activate` isolates dependencies.
- `pip install -r app/requirements.txt` installs FastAPI, transformers, and optional GPU extras.
- `uvicorn app.app:app --reload --port 8080` is the preferred dev loop; it honours `RELOAD=true`.
- `python -m app.app` mirrors the container entrypoint for quick smoke tests.
- `docker build -t moondream-api .` then `docker run -p 8080:8080 moondream-api` validates the image pipeline.
- `python app/test_api.py` exercises every endpoint against a hosted test image; run with the API listening on `localhost:8080`.

## Coding Style & Naming Conventions
- Follow PEP 8 with 4-space indentation and descriptive snake_case function names; classes stay PascalCase.
- Keep FastAPI route handlers async and typed (`QueryRequest`, `PointResponse` in `app/app.py`).
- Prefer module-level constants or env vars for tuning; add docstrings for complex flows and log through the configured `logger`.

## Testing Guidelines
- The existing script is integration-first; ensure the server is up and outbound HTTP is permitted.
- When adding unit tests, colocate them under `app/tests/` and mirror endpoint names (`test_detect_points.py`) for discoverability.
- Capture GPU/CPU branches with explicit assertions so CI can fall back to CPU safely.

## Commit & Pull Request Guidelines
- Recent history favours concise, lower-case summaries (`adding reasoning`, `moondream3`); keep the first line under 72 chars and describe intent.
- Reference issues or PR numbers inline when relevant (`Semver (#1)`).
- PRs should explain model or infrastructure touchpoints, list test evidence (`python app/test_api.py`), and include screenshots or `curl` snippets for API-affecting changes.

## Deployment & Configuration Tips
- `MODEL_REPO_ID`, `MODEL_REVISION`, `REASONING`, `RELOAD`, and `PORT` drive runtime behaviour; document overrides in PRs.
- Update `charts/values.yaml` and the Docker image tag together so the Helm release matches the packaged revision.
- CI images run as the `moondream` user; adjust file ownership in the Dockerfile when introducing new assets.
