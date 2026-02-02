# Git Push Add-on for Home Assistant - Overview

This is a Home Assistant add-on that pushes your configuration files to a Git repository. It's essentially the reverse of the official Git Pull add-on.

## 📦 What's Included

### Core Files
- **config.yaml** - Add-on configuration and schema
- **Dockerfile** - Container build instructions
- **build.yaml** - Multi-architecture build configuration
- **run.sh** - Main script that handles git operations

### Documentation
- **README.md** - Comprehensive user documentation
- **DOCS.md** - In-app documentation for the add-on store
- **SETUP_GUIDE.md** - Step-by-step installation instructions
- **CHANGELOG.md** - Version history
- **example-config.yaml** - Example configuration with comments

### Repository
- **repository.yaml** - Repository metadata for Home Assistant

## 🚀 Quick Start

### 1. Create the Add-on Repository

Create a new GitHub repository and upload these files. Your structure should be:

```
your-repo/
├── repository.yaml
└── git_push/
    ├── config.yaml
    ├── Dockerfile
    ├── build.yaml
    ├── run.sh
    ├── README.md
    ├── DOCS.md
    ├── CHANGELOG.md
    └── SETUP_GUIDE.md
```

### 2. Add to Home Assistant

1. Go to Settings → Add-ons → Add-on Store
2. Click ⋮ menu → Repositories
3. Add your GitHub repository URL
4. Install the "Git Push" add-on

### 3. Configure

Set up your configuration with either:

**SSH (Recommended):**
```yaml
repository: "git@github.com:user/repo.git"
git_user: "Your Name"
git_email: "your@email.com"
deployment_key: ["-----BEGIN..."]
deployment_key_protocol: "ed25519"
auto_push: true
```

**HTTPS:**
```yaml
repository: "https://github.com/user/repo.git"
git_user: "Your Name"
git_email: "your@email.com"
deployment_user: "username"
deployment_password: "token"
auto_push: true
```

## ✨ Features

### Core Functionality
- ✅ Push Home Assistant config to Git
- ✅ SSH and HTTPS authentication
- ✅ Automatic git repository initialization
- ✅ Configurable commit messages
- ✅ Custom ignore patterns (.gitignore)
- ✅ Manual or automatic push
- ✅ Scheduled/repeated push operations
- ✅ Multi-branch support

### Security
- ✅ SSH key authentication
- ✅ Personal access token support
- ✅ Configurable file exclusions
- ✅ Secrets protection

## 🔧 How It Works

1. **Initialize**: Creates/validates git repo in `/config`
2. **Configure**: Sets up authentication (SSH or HTTPS)
3. **Stage**: Adds files respecting `.gitignore` patterns
4. **Commit**: Creates commit with timestamp
5. **Push**: Uploads to remote repository (if auto_push enabled)

The add-on can run:
- **Once**: Manual execution when needed
- **Scheduled**: Automatic pushes at intervals
- **Triggered**: Via Home Assistant automations

## 📝 Configuration Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `repository` | string | Yes | Git repository URL |
| `git_branch` | string | No | Branch name (default: main) |
| `git_user` | string | Yes | Name for commits |
| `git_email` | string | Yes | Email for commits |
| `deployment_key` | list | No | SSH private key (line by line) |
| `deployment_user` | string | No | Username for HTTPS |
| `deployment_password` | password | No | Token for HTTPS |
| `auto_push` | bool | No | Auto-push after commit |
| `commit_message` | string | No | Commit message prefix |
| `push_ignore` | list | No | Files to exclude |
| `repeat.active` | bool | No | Enable scheduling |
| `repeat.interval` | int | No | Seconds between runs |

## 🔐 Security Best Practices

1. **Use private repositories** to protect your configuration
2. **Add secrets.yaml to push_ignore** to prevent exposing sensitive data
3. **Use SSH keys** instead of passwords when possible
4. **Use personal access tokens** for HTTPS (not your account password)
5. **Review ignore patterns** before first push

## 🆚 Comparison with Git Pull

| Feature | Git Pull (Official) | Git Push (This Add-on) |
|---------|-------------------|----------------------|
| Direction | Repository → HA | HA → Repository |
| Use Case | Deploy config | Backup/Version control |
| Typical Flow | Pull → Restart HA | Edit → Commit → Push |
| Merge Handling | Pulls remote changes | Pushes local changes |
| Best For | Production deployment | Development/backup |

## 💡 Use Cases

### 1. Backup
Regular automated backups of your configuration to a remote repository.

### 2. Version Control
Track all changes to your configuration with git history.

### 3. Multi-Instance Sync
Edit on one instance, push, then pull on other instances.

### 4. Development Workflow
- Make changes in Home Assistant
- Add-on commits and pushes
- CI/CD validates changes
- Pull to production environment

### 5. Documentation
Git history serves as a changelog for your configuration.

## 🐛 Troubleshooting

### SSH Connection Issues
- Verify public key is added to Git provider
- Check private key format (each line as list item)
- Ensure correct protocol (rsa vs ed25519)

### Authentication Failures
- Use personal access token, not password
- Verify token has repo write permissions
- Check repository URL is correct

### No Changes Detected
- Verify files aren't in push_ignore
- Check .gitignore patterns
- Ensure actual changes exist

### Permission Errors
- Confirm SSH/HTTPS credentials have write access
- Verify repository exists
- Check repository isn't read-only

## 📚 Additional Resources

- **SETUP_GUIDE.md**: Detailed installation walkthrough
- **README.md**: Complete user documentation
- **example-config.yaml**: Configuration examples with comments
- **DOCS.md**: In-addon documentation

## 🤝 Contributing

This add-on is designed to be simple and focused. Potential improvements:

- Web UI for managing commits
- Selective file pushing
- Merge conflict handling
- Branch switching
- Integration with Home Assistant UI

## 📄 License

MIT License - Feel free to use and modify as needed.

## 🙏 Credits

Inspired by the official Home Assistant Git Pull add-on.

---

**Note**: Remember to edit `repository.yaml` with your actual GitHub repository URL and contact information before publishing!
