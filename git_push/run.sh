#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

readonly REPOSITORY=$(bashio::config 'repository')
readonly GIT_BRANCH=$(bashio::config 'git_branch')
readonly GIT_REMOTE=$(bashio::config 'git_remote')
readonly GIT_USER=$(bashio::config 'git_user')
readonly GIT_EMAIL=$(bashio::config 'git_email')
readonly DEPLOYMENT_USER=$(bashio::config 'deployment_user')
readonly DEPLOYMENT_PASSWORD=$(bashio::config 'deployment_password')
readonly DEPLOYMENT_KEY_PROTOCOL=$(bashio::config 'deployment_key_protocol')
readonly AUTO_PUSH=$(bashio::config 'auto_push')
readonly COMMIT_MESSAGE=$(bashio::config 'commit_message')
readonly REPEAT_ACTIVE=$(bashio::config 'repeat.active')
readonly REPEAT_INTERVAL=$(bashio::config 'repeat.interval')

# Setup SSH
function setup-ssh-key() {
    local key_file
    
    bashio::log.info "Setting up SSH key..."
    
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    if [ "${DEPLOYMENT_KEY_PROTOCOL}" == "rsa" ]; then
        key_file="/root/.ssh/id_rsa"
    else
        key_file="/root/.ssh/id_ed25519"
    fi
    
    bashio::config 'deployment_key' | while read -r line; do
        echo "$line" >> "$key_file"
    done
    
    chmod 600 "$key_file"
    
    # Disable host key checking for git operations
    cat > /root/.ssh/config <<EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
    chmod 600 /root/.ssh/config
    
    bashio::log.info "SSH key configured"
}

# Setup user/password authentication
function setup-user-password() {
    local git_url
    
    if [ -n "${DEPLOYMENT_USER}" ] && [ -n "${DEPLOYMENT_PASSWORD}" ]; then
        bashio::log.info "Setting up credential helper for ${DEPLOYMENT_USER}"
        
        git_url=$(echo "${REPOSITORY}" | sed -E 's#https?://##')
        
        git config --global credential.helper store
        echo "https://${DEPLOYMENT_USER}:${DEPLOYMENT_PASSWORD}@${git_url}" > /root/.git-credentials
        chmod 600 /root/.git-credentials
    fi
}

# Check SSH connection
function check-ssh-connection() {
    local domain
    domain=$(echo "${REPOSITORY}" | sed -E 's#.*@([^:]+):.*#\1#')
    
    if [[ "${REPOSITORY}" == *"@"* ]]; then
        bashio::log.info "Checking SSH connection to ${domain}..."
        
        if ssh -T -o "StrictHostKeyChecking=no" -o "BatchMode=yes" "${domain}" 2>&1 | grep -q "successfully authenticated\|Welcome to GitLab"; then
            bashio::log.info "Valid SSH connection to ${domain}"
            return 0
        else
            bashio::log.warning "No valid SSH connection to ${domain}"
            return 1
        fi
    fi
    return 0
}

# Initialize or validate git repository
function init-git-repo() {
    cd /config || bashio::exit.nok "Cannot access /config directory"
    
    if [ ! -d .git ]; then
        bashio::log.info "Initializing git repository..."
        git init
        git config user.name "${GIT_USER}"
        git config user.email "${GIT_EMAIL}"
        git remote add "${GIT_REMOTE}" "${REPOSITORY}"
        bashio::log.info "Git repository initialized"
    else
        bashio::log.info "Git repository already exists"
        
        # Update remote URL if changed
        current_url=$(git remote get-url "${GIT_REMOTE}" 2>/dev/null || echo "")
        if [ "${current_url}" != "${REPOSITORY}" ]; then
            bashio::log.info "Updating remote URL..."
            git remote set-url "${GIT_REMOTE}" "${REPOSITORY}"
        fi
        
        # Ensure user config is set
        git config user.name "${GIT_USER}"
        git config user.email "${GIT_EMAIL}"
    fi
    
    # Set current branch
    current_branch=$(git branch --show-current)
    if [ -z "${current_branch}" ]; then
        git checkout -b "${GIT_BRANCH}"
    elif [ "${current_branch}" != "${GIT_BRANCH}" ]; then
        git checkout -b "${GIT_BRANCH}" 2>/dev/null || git checkout "${GIT_BRANCH}"
    fi
}

# Setup gitignore from push_ignore config
function setup-gitignore() {
    bashio::log.info "Setting up .gitignore..."
    
    # Start with a clean .gitignore
    cat > /config/.gitignore <<EOF
# Git Push Addon - Auto-generated ignore list
EOF
    
    # Add each ignore pattern
    bashio::config 'push_ignore' | while read -r pattern; do
        echo "${pattern}" >> /config/.gitignore
    done
    
    bashio::log.info ".gitignore configured"
}

# Stage and commit changes
function commit-changes() {
    cd /config || bashio::exit.nok "Cannot access /config directory"
    
    # Add all files respecting .gitignore
    git add -A
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        bashio::log.info "No changes to commit"
        return 1
    fi
    
    # Show what will be committed
    bashio::log.info "Files to be committed:"
    git diff --cached --name-status
    
    # Commit changes
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "${COMMIT_MESSAGE} - ${timestamp}"
    
    bashio::log.info "Changes committed"
    return 0
}

# Push changes to remote
function push-changes() {
    cd /config || bashio::exit.nok "Cannot access /config directory"
    
    bashio::log.info "Pushing to ${GIT_REMOTE}/${GIT_BRANCH}..."
    
    # Try to push, handle the case where remote branch doesn't exist
    if git push "${GIT_REMOTE}" "${GIT_BRANCH}" 2>&1; then
        bashio::log.info "Successfully pushed changes"
    else
        bashio::log.warning "Push failed, trying with --set-upstream..."
        git push --set-upstream "${GIT_REMOTE}" "${GIT_BRANCH}"
        bashio::log.info "Successfully pushed changes with new upstream"
    fi
}

# Main execution function
function execute-git-push() {
    bashio::log.info "Starting Git Push operation..."
    
    # Setup authentication
    if bashio::config.has_value 'deployment_key'; then
        setup-ssh-key
        check-ssh-connection
    fi
    
    if bashio::config.has_value 'deployment_user'; then
        setup-user-password
    fi
    
    # Initialize repository
    init-git-repo
    
    # Setup ignore patterns
    setup-gitignore
    
    # Commit and push
    if commit-changes; then
        if [ "${AUTO_PUSH}" == "true" ]; then
            push-changes
        else
            bashio::log.info "Changes committed but auto-push is disabled"
            bashio::log.info "Run the addon again or enable auto_push to push changes"
        fi
    else
        bashio::log.info "Nothing to push"
    fi
    
    bashio::log.info "Git Push operation completed"
}

# Main loop
bashio::log.info "=========================================="
bashio::log.info "Git Push Add-on"
bashio::log.info "=========================================="

# Validate configuration
if ! bashio::config.has_value 'repository'; then
    bashio::exit.nok "Repository URL is required"
fi

if ! bashio::config.has_value 'git_user'; then
    bashio::exit.nok "Git user name is required"
fi

if ! bashio::config.has_value 'git_email'; then
    bashio::exit.nok "Git email is required"
fi

# Execute push operation
execute-git-push

# Handle repeat mode
if [ "${REPEAT_ACTIVE}" == "true" ]; then
    bashio::log.info "Repeat mode enabled, will run every ${REPEAT_INTERVAL} seconds"
    
    while true; do
        sleep "${REPEAT_INTERVAL}"
        bashio::log.info "Running scheduled push..."
        execute-git-push
    done
else
    bashio::log.info "Repeat mode disabled, exiting"
fi
