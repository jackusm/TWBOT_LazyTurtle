# TWB - Tribal Wars Bot (LazyTurtle fork)
#
# One image runs both the web dashboard and the world bots. The dashboard
# spawns bots itself (Start/Stop buttons), so they must live in the same
# container - do not split them into separate services.
#
# The image only carries the Python dependencies; the code itself is bind-
# mounted from the checkout (see docker-compose.yml), so a code edit needs
# just `docker compose restart` - no rebuild.
#
#   docker compose up -d      build + run
#   docker compose logs -f    watch the bots
FROM python:3.12-slim

# tzdata so the bot's active_hours / night scavenging follow your local clock.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Europe/Amsterdam \
    PORT=5000

WORKDIR /app

# Dependencies first so a requirements change is the only thing that needs a
# rebuild.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# The code is not COPYed in - compose mounts the checkout over /app. Keep the
# import smoke test by bind-mounting the build context just for this step
# (BuildKit, which compose v2 uses by default); it still fails the build early
# if the bot cannot import its own modules.
RUN --mount=type=bind,source=.,target=/app,ro python /app/twb.py -i

EXPOSE 5000

# Via sh so the entrypoint works even when the checkout lacks the exec bit
# (Windows/ macOS git checkouts).
ENTRYPOINT ["/bin/sh", "/app/docker/entrypoint.sh"]
