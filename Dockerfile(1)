FROM python:3.12-slim
WORKDIR /app
COPY servidor.py niveles.py index.html ./
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["python3", "servidor.py"]
