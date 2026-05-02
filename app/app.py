#built to let Github Actions know if the app actually started
from flask import Flask #importing Flask
import json
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG, format='%(message)s')

app = Flask(__name__) #create a Flask app instance

@app.route('/health', methods=['GET']) #create a route that accepts GET requests
def status_message():
    logger.info(json.dumps({"event": "someone checking health", "endpoint": "/health", "status": "healthy"}))
    return { #return a JSON response
        "status": "healthy",
        "message": "azure-appsec-pipeline is running",
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) #all connections that can talk to this host can connect to the API


