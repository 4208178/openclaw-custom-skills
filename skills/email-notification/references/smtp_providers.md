# SMTP Providers Reference

Common SMTP server configurations for email services:

## QQ Email
- SMTP Server: smtp.qq.com
- SSL Port: 465
- TLS Port: 587
- Authentication: Email address + Authorization Code (not password)
- Notes: Requires enabling SMTP service in QQ Mail settings and generating an authorization code

## 163 Email
- SMTP Server: smtp.163.com
- SSL Port: 465
- TLS Port: 994
- Authentication: Email address + Authorization Code

## Gmail
- SMTP Server: smtp.gmail.com
- SSL Port: 465
- TLS Port: 587
- Authentication: Email address + App Password (not regular password)
- Notes: Requires 2-Factor Authentication and App Password generation

## Outlook/Hotmail
- SMTP Server: smtp.office365.com
- TLS Port: 587
- Authentication: Email address + Password
- Notes: May require enabling "Allow apps and devices to use Exchange Web Services"

## Yahoo Mail
- SMTP Server: smtp.mail.yahoo.com
- SSL Port: 465
- TLS Port: 587
- Authentication: Email address + App Password
- Notes: Requires enabling "Allow apps that use less secure sign" or App Password

## General Tips
1. Always use SSL/TLS when available (port 465 for SSL, 587 for TLS)
2. Use authorization codes/app passwords instead of main email passwords when available
3. Test connection with tools like `telnet smtp.server.com 465` or openssl
4. Check spam folder if emails aren't arriving
5. Some providers have daily sending limits