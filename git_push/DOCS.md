# Configuration

## Required Settings

- **repository**: Your Git repository URL
  - SSH: `git@github.com:username/repo.git`
  - HTTPS: `https://github.com/username/repo.git`
- **git_user**: Your name for commits
- **git_email**: Your email for commits

## Authentication

Choose either SSH (recommended) or HTTPS authentication.

### SSH Authentication

1. Generate an SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   ```

2. Add the public key to your Git provider (GitHub, GitLab, etc.)

3. Copy the private key into the configuration:
   ```yaml
   deployment_key:
     - "-----BEGIN OPENSSH PRIVATE KEY-----"
     - "line 2 of key"
     - "line 3 of key"
     - "..."
     - "-----END OPENSSH PRIVATE KEY-----"
   deployment_key_protocol: "ed25519"
   ```

### HTTPS Authentication

```yaml
deployment_user: "your-username"
deployment_password: "your-token-or-password"
```

For GitHub and GitLab, use a personal access token instead of your password.

## Options

### auto_push

When `true`, changes are automatically pushed after being committed. When `false`, changes are only committed locally.

Default: `false`

### commit_message

A prefix for commit messages. The actual commit message will include a timestamp.

Default: `"Update Home Assistant config"`

### push_ignore

List of file patterns to exclude from commits. Supports wildcards.

Example:
```yaml
push_ignore:
  - "secrets.yaml"
  - "*.db"
  - ".storage/"
```

### repeat

Schedule automatic pushes:

```yaml
repeat:
  active: true
  interval: 3600  # seconds
```

## Examples

### Minimal Configuration (SSH)

```yaml
repository: "git@github.com:myuser/ha-config.git"
git_user: "John Doe"
git_email: "john@example.com"
deployment_key:
  - "-----BEGIN OPENSSH PRIVATE KEY-----"
  - "..."
  - "-----END OPENSSH PRIVATE KEY-----"
deployment_key_protocol: "ed25519"
auto_push: true
```

### HTTPS with Scheduled Pushes

```yaml
repository: "https://github.com/myuser/ha-config.git"
git_user: "John Doe"
git_email: "john@example.com"
deployment_user: "myuser"
deployment_password: "ghp_xxxxxxxxxxxxx"
auto_push: true
repeat:
  active: true
  interval: 3600
```

## First Run

On first run, the add-on will:
1. Initialize a git repository in `/config`
2. Add all your configuration files (respecting `.gitignore`)
3. Create an initial commit
4. Push to your repository (if `auto_push` is enabled)

## Subsequent Runs

The add-on will:
1. Check for changes in `/config`
2. Stage and commit changes (if any)
3. Push to remote (if `auto_push` is enabled and there are changes)

## Important Security Notes

- Always add `secrets.yaml` to `push_ignore`
- Use private repositories for your configuration
- Use SSH keys or personal access tokens, not passwords
- Review your configuration before the first push to ensure no sensitive data is included
