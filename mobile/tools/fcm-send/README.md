# Admin-only FCM Sender

This is a small Node CLI that sends a push notification to an FCM topic.

Prereqs
- Node 18+
- A Firebase service account JSON with Messaging permission

Install

- cd tools/fcm-send
- npm install

Usage

- Set GOOGLE_APPLICATION_CREDENTIALS to your service account path,
  or pass --credentials=path\to\serviceAccount.json

Examples

- Windows PowerShell (env var):
  $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccount.json"; node send.js --topic=critical-alerts --title="Test" --body="Hello"

- Using --credentials argument:
  node send.js --credentials="C:\path\to\serviceAccount.json" --topic=critical-alerts --title="Test" --body="Hello" --data.key=value
