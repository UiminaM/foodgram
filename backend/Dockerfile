FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir --no-deps -r requirements.txt

COPY . .

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "foodgram.wsgi:application"]