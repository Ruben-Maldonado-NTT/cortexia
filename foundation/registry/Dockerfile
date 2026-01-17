FROM python:3.11-slim

WORKDIR /app

COPY app/main.py /app/main.py
COPY schemas /app/schemas

# Install dependencies directly
RUN pip install fastapi uvicorn pydantic qdrant-client fastembed

EXPOSE 8090

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8090"]
