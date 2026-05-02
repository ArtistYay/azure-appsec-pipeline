from flask import Flask #importing Flask, need this to create a web app instance
import json #importing JSON module to convert python dictionary to JSON string for logging
import logging #built in logging module, used to write log entries to stdout

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG, format='%(message)s') #configures logging system, log everything, and only output the message it self

app = Flask(__name__) #create a Flask app instance

@app.route('/health', methods=['GET']) #create a route that accepts GET requests
def status_message():
    logger.info(json.dumps({"event": "someone checking health", "endpoint": "/health", "status": "healthy"})) #json.dumps converts a dictionary to a string and logger.info() writes it to stdout at INFO level
    return { #return a JSON response
        "status": "healthy",
        "message": "azure-appsec-pipeline is running",
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) #all connections that can talk to this host can connect to the API


