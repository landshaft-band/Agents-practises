# Используем легковесный образ Python 3.12
FROM python:3.12-slim

# Устанавливаем системные зависимости для сборки нативных пакетов (faiss, numpy и т.д.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Poetry (версия из вашего poetry.lock)
ENV POETRY_VERSION=2.4.1
ENV POETRY_HOME=/opt/poetry
RUN python3 -c "import urllib.request; urllib.request.urlretrieve('https://install.python-poetry.org', '/tmp/install-poetry.py')" \
    && python3 /tmp/install-poetry.py --version ${POETRY_VERSION} \
    && rm /tmp/install-poetry.py
ENV PATH="${POETRY_HOME}/bin:${PATH}"

# Отключаем создание виртуального окружения – ставим пакеты в системный Python
RUN poetry config virtualenvs.create false

WORKDIR /app

# Копируем только файлы зависимостей для кэширования слоёв
COPY pyproject.toml poetry.lock ./

# Устанавливаем все зависимости (без самого проекта как пакета)
# --no-root — чтобы не пытаться установить текущий проект (мы же не пакет)
RUN poetry install --no-interaction --no-ansi --no-root

# Копируем весь остальной код
COPY . .

# Переменные окружения Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Запускаем через run.py (он найдёт корень и запустит бота через poetry run)
CMD ["python", "tg_bot_rag_faq/src/main.py"]
