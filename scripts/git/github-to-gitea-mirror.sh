#!/usr/bin/env bash

# GitHub to Gitea Mirror Import Script
# Imports multiple GitHub repositories to Gitea with mirroring and wiki support

set -euo pipefail

# Configuration
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITEA_URL="${GITEA_URL:-}"
GITEA_TOKEN="${GITEA_TOKEN:-}"
GITEA_USER="${GITEA_USER:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Batch import GitHub repositories to Gitea with mirroring and wiki support.

OPTIONS:
    -h, --help              Show this help message
    -f, --file FILE         File containing list of repos (owner/repo format, one per line)
    -r, --repos REPOS       Comma-separated list of repos (owner/repo format)
    -u, --gitea-url URL     Gitea instance URL (e.g., https://gitea.example.com)
    -t, --gitea-token TOKEN Gitea API token
    -g, --github-token TOKEN GitHub access token
    -U, --gitea-user USER   Gitea username/org to import repos into
    -p, --private           Make imported repos private (default: keep original visibility)
    -m, --mirror-interval   Mirror sync interval in hours (default: 8)

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN    GitHub access token
    GITEA_URL       Gitea instance URL
    GITEA_TOKEN     Gitea API token
    GITEA_USER      Gitea username/org

EXAMPLES:
    # Import from file
    $0 -f repos.txt -u https://gitea.example.com -t gitea_token -g github_token -U myuser

    # Import specific repos
    $0 -r "owner/repo1,owner/repo2" -u https://gitea.example.com -t gitea_token -g github_token -U myuser

    # Using environment variables
    export GITEA_URL="https://gitea.example.com"
    export GITEA_TOKEN="your_gitea_token"
    export GITHUB_TOKEN="your_github_token"
    export GITEA_USER="myuser"
    $0 -f repos.txt

EOF
    exit 1
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required commands are available
check_dependencies() {
    local deps=("curl" "jq")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found. Please install it."
            exit 1
        fi
    done
}

# Validate configuration
validate_config() {
    local errors=0

    if [[ -z "$GITEA_URL" ]]; then
        log_error "Gitea URL is required"
        ((errors++))
    fi

    if [[ -z "$GITEA_TOKEN" ]]; then
        log_error "Gitea token is required"
        ((errors++))
    fi

    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub token is required"
        ((errors++))
    fi

    if [[ -z "$GITEA_USER" ]]; then
        log_error "Gitea user/org is required"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        usage
    fi
}

# Get GitHub repo info
get_github_repo_info() {
    local repo="$1"
    local response

    log_info "Fetching info for GitHub repo: $repo"
    
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$repo")

    if [[ $(echo "$response" | jq -r '.message // empty') == "Not Found" ]]; then
        log_error "Repository $repo not found or inaccessible"
        return 1
    fi

    echo "$response"
}

# Check if repo has wiki enabled
check_github_wiki() {
    local repo="$1"
    local repo_info="$2"
    
    local has_wiki=$(echo "$repo_info" | jq -r '.has_wiki')
    
    if [[ "$has_wiki" != "true" ]]; then
        return 1
    fi

    # Try to access wiki to see if it actually has content
    local wiki_url="https://github.com/$repo.wiki.git"
    if curl -s -f -H "Authorization: token $GITHUB_TOKEN" \
        -o /dev/null -w "%{http_code}" "$wiki_url" | grep -q "200\|301"; then
        return 0
    fi
    
    return 1
}

# Create mirrored repo in Gitea
create_gitea_mirror() {
    local github_repo="$1"
    local repo_info="$2"
    local is_private="$3"
    local mirror_interval="$4"
    
    local repo_name=$(echo "$repo_info" | jq -r '.name')
    local description=$(echo "$repo_info" | jq -r '.description // ""')
    local private=$(echo "$repo_info" | jq -r '.private')
    local clone_url="https://github.com/$github_repo.git"
    
    # Override privacy if specified
    if [[ "$is_private" == "true" ]]; then
        private="true"
    fi

    log_info "Creating mirror for $repo_name in Gitea..."

    local payload=$(jq -n \
        --arg clone_addr "$clone_url" \
        --arg repo_name "$repo_name" \
        --arg description "$description" \
        --argjson private "$private" \
        --arg auth_token "$GITHUB_TOKEN" \
        --arg uid "$GITEA_USER" \
        --arg mirror_interval "${mirror_interval}h" \
        '{
            clone_addr: $clone_addr,
            repo_name: $repo_name,
            description: $description,
            private: $private,
            mirror: true,
            auth_token: $auth_token,
            uid: $uid,
            mirror_interval: $mirror_interval,
            wiki: true,
            issues: true,
            pull_requests: true,
            releases: true,
            labels: true
        }')

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$GITEA_URL/api/v1/repos/migrate")

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
        log_success "Successfully created mirror for $repo_name"
        return 0
    else
        local error_msg=$(echo "$body" | jq -r '.message // .error // "Unknown error"')
        log_error "Failed to create mirror for $repo_name: $error_msg (HTTP $http_code)"
        return 1
    fi
}

# Import a single repository
import_repo() {
    local repo="$1"
    local is_private="$2"
    local mirror_interval="$3"
    
    log_info "========================================="
    log_info "Processing: $repo"
    log_info "========================================="

    # Get GitHub repo info
    local repo_info
    if ! repo_info=$(get_github_repo_info "$repo"); then
        log_error "Skipping $repo due to errors"
        return 1
    fi

    # Create mirror in Gitea
    if ! create_gitea_mirror "$repo" "$repo_info" "$is_private" "$mirror_interval"; then
        log_error "Failed to import $repo"
        return 1
    fi

    # Check for wiki
    if check_github_wiki "$repo" "$repo_info"; then
        log_info "Wiki detected for $repo - it will be mirrored automatically"
    else
        log_info "No wiki found for $repo"
    fi

    log_success "Completed processing $repo"
    echo ""
    return 0
}

# Main function
main() {
    local repos_file=""
    local repos_list=""
    local is_private="false"
    local mirror_interval="8"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -f|--file)
                repos_file="$2"
                shift 2
                ;;
            -r|--repos)
                repos_list="$2"
                shift 2
                ;;
            -u|--gitea-url)
                GITEA_URL="$2"
                shift 2
                ;;
            -t|--gitea-token)
                GITEA_TOKEN="$2"
                shift 2
                ;;
            -g|--github-token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -U|--gitea-user)
                GITEA_USER="$2"
                shift 2
                ;;
            -p|--private)
                is_private="true"
                shift
                ;;
            -m|--mirror-interval)
                mirror_interval="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Check dependencies
    check_dependencies

    # Validate configuration
    validate_config

    # Build repos array
    local repos=()
    if [[ -n "$repos_file" ]]; then
        if [[ ! -f "$repos_file" ]]; then
            log_error "File not found: $repos_file"
            exit 1
        fi
        mapfile -t repos < <(grep -v '^#' "$repos_file" | grep -v '^[[:space:]]*$')
    elif [[ -n "$repos_list" ]]; then
        IFS=',' read -ra repos <<< "$repos_list"
    else
        log_error "Either --file or --repos must be specified"
        usage
    fi

    if [[ ${#repos[@]} -eq 0 ]]; then
        log_error "No repositories specified"
        exit 1
    fi

    # Remove GITEA_URL trailing slash if present
    GITEA_URL="${GITEA_URL%/}"

    # Summary
    log_info "========================================="
    log_info "Starting batch import"
    log_info "========================================="
    log_info "GitHub repos to import: ${#repos[@]}"
    log_info "Gitea URL: $GITEA_URL"
    log_info "Gitea user/org: $GITEA_USER"
    log_info "Mirror interval: ${mirror_interval}h"
    log_info "Force private: $is_private"
    log_info "========================================="
    echo ""

    # Import each repo
    local success=0
    local failed=0

    for repo in "${repos[@]}"; do
        # Trim whitespace
        repo=$(echo "$repo" | xargs)
        
        # Skip empty lines and comments
        [[ -z "$repo" || "$repo" =~ ^# ]] && continue

        if import_repo "$repo" "$is_private" "$mirror_interval"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    # Final summary
    echo ""
    log_info "========================================="
    log_info "Import Summary"
    log_info "========================================="
    log_success "Successfully imported: $success"
    if [[ $failed -gt 0 ]]; then
        log_error "Failed imports: $failed"
    fi
    log_info "========================================="

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Run main function
main "$@"
