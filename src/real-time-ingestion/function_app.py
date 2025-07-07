import logging
import os
import requests
import datetime
import azure.functions as func

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

# --- CONFIGURATION ---
API_KEY = os.environ["DELIJN_API_KEY"]
STORAGE_ACCOUNT_URL = os.environ["STORAGE_ACCOUNT_URL"]
STORAGE_CONTAINER_NAME = os.environ["STORAGE_CONTAINER_NAME"]

credential = DefaultAzureCredential()

blob_service_client = BlobServiceClient(
    account_url=STORAGE_ACCOUNT_URL, credential=credential
)

# --- FUNCTIONS ---
app = func.FunctionApp()


# The schedule is a CRON expression for "every 5 minutes".
@app.schedule(
    schedule="0 */5 * * * *", arg_name="myTimer", run_on_startup=True, use_monitor=False
)
def real_time_ingestor(myTimer: func.TimerRequest) -> None:

    utc_timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    if myTimer.past_due:
        logging.info("The timer is past due!")

    logging.info("Python timer trigger function ran at %s", utc_timestamp)

    try:
        # 1. Call the De Lijn API
        api_url = "https://api.delijn.be/gtfs/v3/realtime?json=true"
        headers = {
            "Cache-Control": "no-cache",
            "Ocp-Apim-Subscription-Key": API_KEY,
        }

        logging.info(f"Calling De Lijn API at {api_url}...")
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()
        logging.info("Successfully received data from API.")

        # 2. Save the Raw Data to ADLS
        now = datetime.datetime.now(datetime.timezone.utc)
        file_name = f"raw/{now.year}/{now.month:02d}/{now.day:02d}/{now.strftime('%Y-%m-%dT%H-%M-%S')}.json"

        blob_client = blob_service_client.get_blob_client(
            container=STORAGE_CONTAINER_NAME, blob=file_name
        )

        logging.info(f"Uploading data to blob: {file_name}")
        blob_client.upload_blob(data, blob_type="BlockBlob")
        logging.info("Upload complete.")

    except Exception as e:
        logging.error(f"An error occurred: {e}")
