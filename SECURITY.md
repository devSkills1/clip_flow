# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of Clip Flow Pro seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please Do NOT

- Open a public GitHub issue for the vulnerability
- Disclose the vulnerability publicly before it has been addressed
- Exploit the vulnerability for malicious purposes

### Please DO

Send an email to **jr.lu.jobs@gmail.com** with the following information:

1. **Description**: A clear description of the vulnerability
2. **Steps to Reproduce**: Detailed steps to reproduce the issue
3. **Impact**: The potential impact of the vulnerability
4. **Affected Version**: The version(s) of Clip Flow Pro affected
5. **Possible Fix**: If you have suggestions for how to fix the issue (optional)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within **48 hours**
- **Communication**: We will keep you informed about our progress in addressing the vulnerability
- **Timeline**: We aim to address critical vulnerabilities within **7 days** and other vulnerabilities within **30 days**
- **Credit**: If you would like, we will credit you in our release notes when we fix the vulnerability

## Security Best Practices for Users

### Data Storage

- Clip Flow Pro stores clipboard history locally on your device
- Sensitive data can be encrypted using AES-256 encryption (enable in Settings > Security)
- Database files are stored in the application support directory

### Encryption

When encryption is enabled:
- All clipboard content is encrypted before being stored
- Encryption keys are securely managed by the application
- We recommend enabling encryption if you frequently copy sensitive information

### Permissions

Clip Flow Pro requires the following permissions:
- **Clipboard Access**: To monitor and store clipboard history
- **File System Access**: To store data and handle file clipboard items
- **Accessibility** (optional): For global hotkey functionality on some platforms

## Security Features

- **Local-only Storage**: All data is stored locally; no cloud sync or remote servers
- **Optional Encryption**: AES-256 encryption for sensitive data
- **No Analytics**: No tracking or analytics data is collected
- **Open Source**: Full source code is available for security audits

## Contact

For security concerns, please contact: **jr.lu.jobs@gmail.com**

For general questions and support, please use [GitHub Issues](https://github.com/Jemiking/Clip-Flow-Pro/issues).
