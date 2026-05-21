# creates an alpine image (minimal image) with python 3.12 installed.
FROM python:3.12-alpine

# the working directory in the docker container, creates it if needed.
WORKDIR /app

# copies my requirements.txt file from my local folder into 
# docker in the working directory.
COPY requirements.txt .

# installs all dependencies from the requirements file.
RUN pip3 install -r requirements.txt

# copies all my files in the app local folder to the docker app folder.
COPY app/ .

# builds the flask app using gunicorn on port 50000.
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:5000", "app:app"]