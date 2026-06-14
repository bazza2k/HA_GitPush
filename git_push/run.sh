#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Do NOT use set -e — handle errors explicitly

# ---------------------------------------------------------------------------
# Read configuration
# ---------------------------------------------------------------------------
readonly GIT_HOST=$(bashio::config 'git_host')
readonly GIT_PORT=$(bashio::config 'git_port')
readonly GIT_REPOSITORY=$(bashio::config 'git_repository')
readonly GIT_BRANCH=$(bashio::config 'git_branch')
readonly GIT_REMOTE=$(bashio::config 'git_remote')
readonly GIT_USER=$(bashio::config 'git_user')
readonly GIT_EMAIL=$(bashio::config 'git_email')
readonly AUTH_METHOD=$(bashio::config 'auth_method')
readonly DEPLOYMENT_USER=$(bashio::config 'deployment_user')
readonly DEPLOYMENT_PASSWORD=$(bashio::config 'deployment_password')
readonly DEPLOYMENT_KEY_PROTOCOL=$(bashio::config 'deployment_key_protocol')
readonly AUTO_PUSH=$(bashio::config 'auto_push')
readonly COMMIT_MESSAGE=$(bashio::config 'commit_message')
readonly REPEAT_ACTIVE=$(bashio::config 'repeat.active')
readonly REPEAT_INTERVAL=$(bashio::config 'repeat.interval')

readonly SSH_DIR="/config/.addon_data/ssh"
readonly DATA_DIR="/config/.addon_data"

# ---------------------------------------------------------------------------
# Build the remote URL depending on auth method
#
# SSH (port 22):  git@host:user/repo.git
# SSH (non-22):   ssh://git@host:port/user/repo.git   <-- SCP shorthand
#                 doesn't support custom ports, must use ssh:// URL form
# HTTPS:          https://user:pass@host:port/user/repo.git
# ---------------------------------------------------------------------------
function build-repo-url() {
    if [ "${AUTH_METHOD}" == "ssh_key" ]; then
        if [ "${GIT_PORT}" == "22" ]; then
            # Standard SCP-style shorthand
            echo "git@${GIT_HOST}:${GIT_REPOSITORY}"
        else
            # ssh:// URL form required for non-standard ports
            echo "ssh://git@${GIT_HOST}:${GIT_PORT}/${GIT_REPOSITORY}"
        fi
    else
        # HTTPS with embedded credentials
        local protocol="https"
        [ "${GIT_PORT}" == "80" ] && protocol="http"

        local encoded_password
        encoded_password=$(python3 -c \
            "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" \
            "${DEPLOYMENT_PASSWORD}")

        echo "${protocol}://${DEPLOYMENT_USER}:${encoded_password}@${GIT_HOST}:${GIT_PORT}/${GIT_REPOSITORY}"
    fi
}

# ---------------------------------------------------------------------------
# SSH key auth setup
# ---------------------------------------------------------------------------
function setup-ssh() {
    bashio::log.info "Setting up SSH authentication..."

    mkdir -p "${SSH_DIR}"
    chmod 700 "${SSH_DIR}"
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh

    # Write private key from options.json array
    local key_file="${SSH_DIR}/id_${DEPLOYMENT_KEY_PROTOCOL}"
    : > "${key_file}"
    jq -r '.deployment_key[]' /data/options.json >> "${key_file}"
    chmod 600 "${key_file}"
    ln -sf "${key_file}" "/root/.ssh/id_${DEPLOYMENT_KEY_PROTOCOL}"

    # Write SSH client config with explicit port
    # This ensures git ssh uses the right port for every connection to this host
    cat > "${SSH_DIR}/config" << EOF
Host ${GIT_HOST}
    HostName ${GIT_HOST}
    Port ${GIT_PORT}
    User git
    IdentityFile ${SSH_DIR}/id_${DEPLOYMENT_KEY_PROTOCOL}
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    UserKnownHostsFile ${SSH_DIR}/known_hosts
EOF
    chmod 600 "${SSH_DIR}/config"
    ln -sf "${SSH_DIR}/config" /root/.ssh/config

    # Scan host keys on the correct port
    bashio::log.info "Scanning host keys for ${GIT_HOST} on port ${GIT_PORT}..."
    if ssh-keyscan -p "${GIT_PORT}" -H "${GIT_HOST}" > "${SSH_DIR}/known_hosts" 2>/dev/null; then
        local key_count
        key_count=$(wc -l < "${SSH_DIR}/known_hosts")
        bashio::log.info "Stored ${key_count} host key(s)"
    else
        bashio::exit.nok "ssh-keyscan failed for ${GIT_HOST}:${GIT_PORT} — check host and port"
    fi
    chmod 644 "${SSH_DIR}/known_hosts"

    # Quick connectivity test — exit code doesn't matter for git servers,
    # what matters is that we don't get a host key error
    bashio::log.info "Testing SSH connectivity to ${GIT_HOST}:${GIT_PORT}..."
    local ssh_output
    ssh_output=$(ssh -T -o "BatchMode=yes" "${GIT_HOST}" 2>&1 || true)
    bashio::log.info "SSH test response: ${ssh_output}"

    bashio::log.info "SSH setup complete"
}

# ---------------------------------------------------------------------------
# Global git config
# ---------------------------------------------------------------------------
function setup-git-config() {
    bashio::log.info "Writing git configuration..."

    mkdir -p "${DATA_DIR}"
    chmod 700 "${DATA_DIR}"

    cat > "${DATA_DIR}/.gitconfig" << EOF
[user]
    name = ${GIT_USER}
    email = ${GIT_EMAIL}
[init]
    defaultBranch = ${GIT_BRANCH}
[http]
    sslVerify = false
EOF

    ln -sf "${DATA_DIR}/.gitconfig" /root/.gitconfig
    bashio::log.info "Git configuration written"
}

# ---------------------------------------------------------------------------
# Init or update local git repo in /config
# ---------------------------------------------------------------------------
function init-git-repo() {
    local repo_url
    repo_url=$(build-repo-url)

    bashio::log.info "Remote URL: $(echo "${repo_url}" | sed 's|://[^@]*@|://***@|')"

    cd /config || bashio::exit.nok "Cannot access /config directory"

    if [ ! -d .git ]; then
        bashio::log.info "Initialising git repository..."
        git init
        git remote add "${GIT_REMOTE}" "${repo_url}"
    else
        bashio::log.info "Git repository exists, updating remote..."
        git remote set-url "${GIT_REMOTE}" "${repo_url}"
    fi

    git config user.name "${GIT_USER}"
    git config user.email "${GIT_EMAIL}"

    local current_branch
    current_branch=$(git branch --show-current)
    if [ -z "${current_branch}" ]; then
        git checkout -b "${GIT_BRANCH}"
    elif [ "${current_branch}" != "${GIT_BRANCH}" ]; then
        git checkout -b "${GIT_BRANCH}" 2>/dev/null || git checkout "${GIT_BRANCH}"
    fi
}

# ---------------------------------------------------------------------------
# Write .gitignore
# ---------------------------------------------------------------------------
function setup-gitignore() {
    bashio::log.info "Writing .gitignore..."

    printf '# Git Push Addon - auto-generated, do not edit\n' > /config/.gitignore

    local options_file="/data/options.json"
    if [ ! -f "${options_file}" ]; then
        bashio::log.warning "Options file not found, skipping ignore patterns"
        return 0
    fi

    local count
    count=$(jq '.push_ignore | length' "${options_file}")
    [ "${count}" -gt 0 ] && jq -r '.push_ignore[]' "${options_file}" >> /config/.gitignore

    bashio::log.info ".gitignore written with ${count} patterns"
}

# ---------------------------------------------------------------------------
# Commit
# ---------------------------------------------------------------------------
function commit-changes() {
    cd /config || bashio::exit.nok "Cannot access /config directory"

    git add -A

    if git diff --cached --quiet; then
        bashio::log.info "No changes to commit"
        return 1
    fi

    bashio::log.info "Staged files:"
    git diff --cached --name-status

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "${COMMIT_MESSAGE} - ${timestamp}"
    bashio::log.info "Committed"
    return 0
}

# ---------------------------------------------------------------------------
# Push
# ---------------------------------------------------------------------------
function push-changes() {
    cd /config || bashio::exit.nok "Cannot access /config directory"

    local repo_url
    repo_url=$(build-repo-url)

    bashio::log.info "Pushing ${GIT_BRANCH} to ${GIT_HOST}:${GIT_PORT}..."

    if git push "${repo_url}" "${GIT_BRANCH}" 2>&1; then
        bashio::log.info "Push successful"
    else
        bashio::log.info "Retrying with --set-upstream..."
        if git push --set-upstream "${repo_url}" "${GIT_BRANCH}" 2>&1; then
            bashio::log.info "Push successful (upstream set)"
        else
            bashio::exit.nok "Push failed — check host, port, credentials and repository path"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
function execute-git-push() {
    bashio::log.info "Starting Git Push..."

    setup-git-config

    if [ "${AUTH_METHOD}" == "ssh_key" ]; then
        setup-ssh
    fi

    init-git-repo
    setup-gitignore

    if commit-changes; then
        if [ "${AUTO_PUSH}" == "true" ]; then
            push-changes
        else
            bashio::log.info "auto_push disabled — committed locally only"
        fi
    else
        bashio::log.info "Nothing to push"
    fi

    bashio::log.info "Done"
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
bashio::log.info "=========================================="
bashio::log.info " Git Push Add-on"
bashio::log.info "=========================================="
bashio::log.info "Auth method : ${AUTH_METHOD}"
bashio::log.info "Host        : ${GIT_HOST}"
bashio::log.info "Port        : ${GIT_PORT}"
bashio::log.info "Repository  : ${GIT_REPOSITORY}"
bashio::log.info "Branch      : ${GIT_BRANCH}"

for field in git_host git_repository git_user git_email; do
    if ! bashio::config.has_value "${field}"; then
        bashio::exit.nok "Required config field '${field}' is missing"
    fi
done

if [ "${AUTH_METHOD}" == "ssh_key" ]; then
    if ! bashio::config.has_value 'deployment_key'; then
        bashio::exit.nok "auth_method is ssh_key but deployment_key is missing"
    fi
else
    for field in deployment_user deployment_password; do
        if ! bashio::config.has_value "${field}"; then
            bashio::exit.nok "auth_method is https but '${field}' is missing"
        fi
    done
fi

execute-git-push

if [ "${REPEAT_ACTIVE}" == "true" ]; then
    bashio::log.info "Repeat mode — running every ${REPEAT_INTERVAL}s"
    while true; do
        sleep "${REPEAT_INTERVAL}"
        execute-git-push
    done
else
    bashio::log.info "Repeat mode disabled, exiting"
fi
