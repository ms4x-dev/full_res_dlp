#!/usr/bin/env python3
import subprocess
import os
import re
import sys
import requests
import time
from datetime import datetime

# --- Configuration ---
url = "https://www.mywebsite.com/watch?v=ZyWelvEP_CQ"
cookies_file = os.path.expanduser("~/Library/Application Support/yt_dlp_gui/forged_cookies.txt")
output_dir = os.path.expanduser("~/Downloads/%(title)s.%(ext)s")
user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
referer = "https://www.mywebsite.com/"
max_retries = 5
retry_delay = 5  # seconds

# --- Log setup ---
script_dir = os.path.dirname(os.path.abspath(__file__))
log_file = os.path.join(script_dir, "yt_download.log")

def log(message, success=None):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    prefix = ""
    if success is True:
        prefix = "✅ "
    elif success is False:
        prefix = "❌ "
    line = f"{timestamp} {prefix}{message}"
    print(line)
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(line + "\n")

log("=== Starting yt-dlp download script ===")

# --- Ensure directories ---
os.makedirs(os.path.dirname(output_dir), exist_ok=True)
if not os.path.isfile(cookies_file):
    log(f"Cookies file not found: {cookies_file}", success=False)
    sys.exit(1)
log(f"Output directory: {output_dir}")
log(f"Cookies file: {cookies_file}")

# --- Fetch page content ---
headers = {
    "User-Agent": user_agent,
    "Referer": referer
}

try:
    with open(cookies_file, "r") as f:
        cookie_content = f.read()
    resp = requests.get(url, headers=headers, cookies={"Cookie": cookie_content})
    resp.raise_for_status()
    content = resp.text
    log("Fetched webpage successfully.", success=True)
except Exception as e:
    log(f"Failed to fetch page: {e}", success=False)
    sys.exit(1)

# --- Extract PO token & XSRF token ---
po_match = re.search(r'html5_web_po_request_key\\u003d([A-Za-z0-9_-]+)', content)
xsrf_match = re.search(r'XSRF_TOKEN\\":\\s*\\"([A-Za-z0-9_=]+)\\"', content)

if not po_match or not xsrf_match:
    log("Failed to extract po_token or xsrf_token from the page.", success=False)
    sys.exit(1)

po_token = po_match.group(1)
xsrf_token = xsrf_match.group(1)
log(f"Extracted po_token: {po_token}")
log(f"Extracted xsrf_token: {xsrf_token}")

# --- Build yt-dlp command ---
format_chain = "bv*[height=2160]+ba/best"
cmd = [
    "yt-dlp",
    url,
    "--cookies", cookies_file,
    "--extractor-args", f"mywebsite:po_token={po_token}:xsrf_token={xsrf_token}",
    "--format", format_chain,
    "--output", output_dir,
    "--add-header", f"User-Agent: {user_agent}",
    "--add-header", f"Referer: {referer}",
    "--remux-video", "mp4",
    "--abort-on-error",
]

log(f"Built yt-dlp command: {' '.join(cmd)}")

# --- Retry download ---
for attempt in range(1, max_retries + 1):
    log(f"Attempt {attempt} of {max_retries}...")
    try:
        subprocess.run(cmd, check=True)
        log("Download completed successfully.", success=True)
        break
    except subprocess.CalledProcessError as e:
        log(f"Download failed with exit code {e.returncode}", success=False)
        # Fallback logic if SABR/4K fails
        if attempt == 1:
            fallback_cmd = cmd.copy()
            fallback_cmd[fallback_cmd.index("--format") + 1] = "bv*[height=1440]+ba/best"
            log("Switching to 1440p fallback.", success=True)
            cmd = fallback_cmd
        elif attempt == 2:
            fallback_cmd = cmd.copy()
            fallback_cmd[fallback_cmd.index("--format") + 1] = "bv*[height=1080]+ba/best"
            log("Switching to 1080p fallback.", success=True)
            cmd = fallback_cmd
        if attempt < max_retries:
            log(f"Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)
        else:
            log("Max retries reached. Exiting.", success=False)
            sys.exit(e.returncode)

log("=== Script finished ===")
