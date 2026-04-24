---
name: email-notification
description: Send emails via SMTP using Python scripts. Use when you need to send reports, notifications, or alerts via email. Supports QQ email and other SMTP providers with authentication.
---

# Email Notification Skill

Send emails via SMTP using Python scripts. This skill provides a reliable way to send reports, notifications, and alerts through email.

## When to Use This Skill

Use this skill when:
- You need to send self-check reports or analysis results via email
- You want to notify yourself about completed tasks or system status
- You need to send automated alerts or reminders
- You have SMTP credentials configured (like QQ email authorization code)

## Core Workflow

### 1. Prepare Content
- Have the report or message content ready (file or text)
- Ensure you have SMTP server details and authentication credentials

### 2. Use the Email Script
- Run the provided Python email script with your content
- The script handles SMTP connection, authentication, and sending

### 3. Verify Delivery
- Check that the email was sent successfully
- Confirm receipt in your inbox (check spam folder if needed)

## Provided Resources

### Scripts
- `scripts/send_report_email.py` - Sends a file as email body
- `scripts/send_screenshot_email.py` - Sends emails with image attachments (example)
- `scripts/send_test_email.py` - Simple test email script

### Configuration
All scripts use the same SMTP configuration:
- Server: `smtp.qq.com` (QQ email)
- Port: `465` (SSL)
- Authentication: Email address + authorization code

## Usage Examples

### Send a Report File
```bash
python3 /home/myuser/.openclaw/workspace/skills/email-notification/scripts/send_report_email.py
```

### Send Custom Content
Modify the script to:
1. Change `REPORT_PATH` to your file path
2. Or modify the `body` variable to send custom text
3. Update recipient if needed (currently sends to self)

## How It Works

The email scripts:
1. Create a MIME multipart message
2. Set From/To/Subject headers
3. Attach content as plain text
4. Connect to SMTP server via SSL
5. Authenticate using email + authorization code
6. Send the message and close connection

## Security Notes

- Authorization codes are app-specific passwords, not your main email password
- Never share authorization codes in public channels
- The scripts store credentials in plain text - consider using environment variables for production
- QQ email requires enabling SMTP service and generating an authorization code

## Customization

To adapt this skill for other email providers:
1. Change `SMTP_SERVER` and `SMTP_PORT` in the script
2. Update authentication method if needed (some providers use different auth)
3. Modify the email content formatting as required

## Troubleshooting

If email sending fails:
1. Verify internet connectivity
2. Check SMTP server address and port
3. Confirm authorization code is valid (not expired)
4. Check if SMTP service is enabled for your email account
5. Look for error messages in script output