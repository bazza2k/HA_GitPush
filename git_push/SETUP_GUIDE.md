# Git Push Add-on - Setup Guide

## Quick Start

### 1. Create the Add-on Repository

Create a new directory structure for your Home Assistant add-on:

```
your-addon-repo/
├── repository.yaml
└── git_push/
    ├── config.yaml
    ├── Dockerfile
    ├── build.yaml
    ├── run.sh
    ├── README.md
    ├── DOCS.md
    └── CHANGELOG.md
```

### 2. Push to GitHub

1. Create a new repository on GitHub (e.g., `hassio-git-push`)
2. Copy all files from the `git_push` folder to your repository
3. Make sure `repository.yaml` is in the root
4. Push to GitHub:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/hassio-git-push.git
git push -u origin main
```

### 3. Add Repository to Home Assistant

1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu (⋮) in the top right
3. Select **Repositories**
4. Add your repository URL: `https://github.com/yourusername/hassio-git-push`
5. Click **Add**

### 4. Install the Add-on

1. Refresh the Add-on Store
2. Scroll down to find "Git Push" under your repositories
3. Click on it and click **Install**
4. Wait for installation to complete

### 5. Configure the Add-on

1. Go to the **Configuration** tab
2. Fill in your settings (see example below)
3. Click **Save**

### 6. Start the Add-on

1. Go to the **Info** tab
2. Click **Start**
3. Check the **Log** tab to verify it's working

## Configuration Example

### Using SSH (Recommended)

```yaml
repository: "git@github.com:yourusername/home-assistant-config.git"
git_branch: "main"
git_remote: "origin"
git_user: "Your Name"
git_email: "your.email@example.com"
deployment_key:
  - "-----BEGIN OPENSSH PRIVATE KEY-----"
  - "b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW"
  - "QyNTUxOQAAACBKitGJJLzH8JGJb9K3H0YJJTjKQFP9EB8YB0A3gBqcZAAAAJguRZoZLkWa"
  - "GQAAAAtzc2gtZWQyNTUxOQAAACBKitGJJLzH8JGJb9K3H0YJJTjKQFP9EB8YB0A3gBqcZA"
  - "AAAECEJhNHZxjEk5x7XUg4TGk4rPLKGJ8nF5H2B3K8Pzb8"
  - "-----END OPENSSH PRIVATE KEY-----"
deployment_key_protocol: "ed25519"
auto_push: true
commit_message: "Auto-update config"
push_ignore:
  - ".git/"
  - "secrets.yaml"
  - "*.db"
  - ".storage/"
  - ".uuid"
  - "home-assistant*.log"
repeat:
  active: false
  interval: 300
```

### Using HTTPS

```yaml
repository: "https://github.com/yourusername/home-assistant-config.git"
git_branch: "main"
git_remote: "origin"
git_user: "Your Name"
git_email: "your.email@example.com"
deployment_user: "yourusername"
deployment_password: "ghp_xxxxxxxxxxxxxxxxxxxx"
auto_push: true
commit_message: "Auto-update config"
push_ignore:
  - ".git/"
  - "secrets.yaml"
  - "*.db"
repeat:
  active: true
  interval: 3600
```

## Important Notes

1. **Create your config repository first** on GitHub/GitLab before starting the add-on
2. **Use SSH keys** for better security (recommended over HTTPS)
3. **Add secrets.yaml to push_ignore** to keep sensitive data safe
4. **Make repository private** to protect your configuration
5. The first push will commit all files in `/config` (except ignored ones)

## Troubleshooting

### Add-on won't start
- Check the logs for error messages
- Verify your repository URL is correct
- Ensure SSH key is properly formatted (each line as separate item in list)

### Authentication failed
- For GitHub: Use a Personal Access Token instead of password
- For SSH: Verify public key is added to your Git provider
- Check credentials are correct

### No changes detected
- Make sure files aren't in the `push_ignore` list
- Check if `.gitignore` is excluding your files
- Verify you've actually made changes to your configuration

## Getting Personal Access Token (GitHub)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token"
3. Select scopes: `repo` (all)
4. Generate and copy the token
5. Use this token as `deployment_password`
