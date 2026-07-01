FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir more-itertools numba numpy tiktoken tqdm \
    && pip install --no-cache-dir --no-deps openai-whisper

RUN useradd --create-home --shell /usr/sbin/nologin appuser

WORKDIR /app
COPY src/transcribe_tui.py /app/transcribe_tui.py

USER appuser
CMD ["python", "/app/transcribe_tui.py"]
