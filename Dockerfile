# creates an alpine image (minimal image) with python 3.12 installed.
FROM python:3.12-alpine

# don't write .pyc files, and send python output straight to the logs without buffering
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# pull in the latest patched OS packages, the base image can be weeks behind
RUN apk upgrade --no-cache

# the working directory in the docker container, creates it if needed.
WORKDIR /app

# copies my requirements.txt file into the working directory first,
# so Docker can cache the dependency layer between builds.
COPY requirements.txt .

# installs all dependencies from the requirements file, without keeping pip's download cache in the image.
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# copies all my files in the app local folder to the docker app folder.
COPY app/ .

# create an unprivileged user and switch to it. If someone breaks out of the app,
# they land as a normal user instead of root inside the container.
RUN adduser -D -H appuser
USER appuser

EXPOSE 5000

# runs the flask app using gunicorn on port 5000.
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "app:app"]
