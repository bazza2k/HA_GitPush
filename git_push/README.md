# Git Push Add-on for Home Assistant

Push your Home Assistant configuration files to a Git repository for version control and backup.

## About

This add-on is the reverse of the built-in Git Pull add-on. Instead of pulling configuration from a Git repository, it pushes your Home Assistant configuration to a Git repository. This is useful for:

- **Backup**: Keep your configuration safely stored in a remote repository
- **Version Control**: Track changes to your configuration over time
- **Collaboration**: Share your configuration with others or across multiple instances
- **Documentation**: Use git history to understand when and why changes were made

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "Git Push" add-on
3. Configure the add-on (see Configuration section below)
4. Start the add-on

## Configuration

### Basic Configuration

```yaml
repository: "git@github.com:yourusername/home-assistant-config.git"
git_branch: "main"
git_remote: "origin"
git_user: "Your Name"
git_email: "your.email@example.com"
```

### SSH Authentication (Recommended)

For SSH authentication, generate an SSH key pair and add the public key to your Git provider:

```yaml
deployment_key:
  - "-----BEGIN OPENSSH PRIVATE KEY-----"
  - "your"
  - "private"
  - "key"
  - "here"
  - "-----END OPENSSH PRIVATE KEY-----"
deployment_key_protocol: "ed25519"  # or "rsa"
```

**To generate an SSH key:**

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

Then copy the contents of the private key (usually `~/.ssh/id_ed25519`) into the `deployment_key` field, with each line as a separate list item.

Add the public key (`~/.ssh/id_ed25519.pub`) to your Git provider:
- GitHub: Settings → SSH and GPG keys
- GitLab: Settings → SSH Keys
- Bitbucket: Personal settings → SSH keys

### HTTPS Authentication

Alternatively, use HTTPS with username and password:

```yaml
repository: "https://github.com/yourusername/home-assistant-config.git"
deployment_user: "yourusername"
deployment_password: "your-personal-access-token"
```

**Note**: For GitHub and GitLab, use a personal access token instead of your password.

### Auto-Push

Enable automatic pushing after each commit:

```yaml
auto_push: true
commit_message: "Update Home Assistant config"
```

### Scheduled Pushes

Run the add-on on a schedule:

```yaml
repeat:
  active: true
  interval: 3600  # Run every hour (in seconds)
```

### Ignore Files

Specify files and patterns to exclude from commits:

```yaml
push_ignore:
  - ".git/"
  - "secrets.yaml"
  - "ip_bans.yaml"
  - ".HA_VERSION"
  - ".storage/"
  - ".uuid"
  - "home-assistant.log*"
  - "deps/"
  - "tts/"
  - "*.db"
  - "*.db-shm"
  - "*.db-wal"
```

## Configuration Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `repository` | Yes | - | Git repository URL (SSH or HTTPS) |
| `git_branch` | No | `main` | Branch to push to |
| `git_remote` | No | `origin` | Remote name |
| `git_user` | Yes | - | Your name for git commits |
| `git_email` | Yes | - | Your email for git commits |
| `deployment_user` | No | - | Username for HTTPS authentication |
| `deployment_password` | No | - | Password/token for HTTPS authentication |
| `deployment_key` | No | - | Private SSH key (as array of lines) |
| `deployment_key_protocol` | No | `rsa` | SSH key type (`rsa` or `ed25519`) |
| `auto_push` | No | `false` | Automatically push after commit |
| `commit_message` | No | `Update Home Assistant config` | Commit message prefix |
| `push_ignore` | No | See above | Files to exclude from commits |
| `repeat.active` | No | `false` | Enable scheduled pushes |
| `repeat.interval` | No | `300` | Interval in seconds between pushes |

## Usage

### First-Time Setup

1. Create an empty repository on your Git provider (GitHub, GitLab, etc.)
2. Configure the add-on with your repository URL and credentials
3. Start the add-on
4. The add-on will initialize the git repository in `/config` and push your configuration

### Subsequent Runs

- **Manual**: Start the add-on whenever you want to commit and push changes
- **Automatic**: Enable `repeat.active` to run on a schedule
- **Automation**: Trigger the add-on from a Home Assistant automation

### Automation Example

You can start the add-on from an automation:

```yaml
automation:
  - alias: "Push config after change"
    trigger:
      - platform: state
        entity_id: input_boolean.config_changed
        to: "on"
    action:
      - service: hassio.addon_start
        data:
          addon: local_git_push
```

## Important Notes

1. **Secrets**: Make sure to add `secrets.yaml` to `push_ignore` to prevent pushing sensitive data
2. **Initial Push**: The first run may take longer as it commits all existing files
3. **Conflicts**: If you edit files both locally and remotely, you may encounter merge conflicts. This add-on doesn't handle merges automatically.
4. **Private Repository**: Consider using a private repository to keep your configuration secure

## Troubleshooting

### SSH Connection Failed

- Verify your private key is correctly formatted in the configuration
- Ensure the public key is added to your Git provider
- Check that the repository URL is correct

### Authentication Failed (HTTPS)

- For GitHub/GitLab, use a personal access token instead of your password
- Ensure the token has repository write permissions

### Nothing to Push

- Check the logs to see if files are being ignored
- Verify that there are actual changes in your configuration
- Review your `push_ignore` patterns

### Permission Denied

- Ensure your SSH key or credentials have write access to the repository
- Check if your repository exists and the URL is correct

## Support

For issues and feature requests, please open an issue on GitHub.

## License

MIT License
