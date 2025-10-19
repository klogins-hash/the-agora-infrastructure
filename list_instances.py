import requests
import os

api_key = os.environ['EXOSCALE_API_KEY']
api_secret = os.environ['EXOSCALE_API_SECRET']

# Try to list instances using the v2 API
url = "https://api-ch-gva-2.exoscale.com/v2/instance"
response = requests.get(url, auth=(api_key, api_secret))
print(f"Status: {response.status_code}")
print(f"Response: {response.text[:500]}")
