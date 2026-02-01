#!/usr/bin/env bash
# Azure DevOps provider for god-mode
# Uses `az` CLI for authentication and REST API for data

# Get Azure DevOps access token
_azure_get_token() {
    az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>/dev/null
}

# Make authenticated API call to Azure DevOps
# Usage: _azure_api "GET" "https://dev.azure.com/org/project/_apis/..."
_azure_api() {
    local method="$1"
    local url="$2"
    local token
    token=$(_azure_get_token)
    
    if [[ -z "$token" ]]; then
        echo "[]" >&2
        return 1
    fi
    
    curl -s -X "$method" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        "$url" 2>/dev/null || echo "{}"
}

# Check if az CLI is available and authenticated
azure_check_auth() {
    if ! command -v az &>/dev/null; then
        echo '{"available":false,"authenticated":false,"user":null,"message":"Azure CLI not installed"}'
        return 1
    fi

    if az account show &>/dev/null; then
        local user
        user=$(az account show --query user.name -o tsv 2>/dev/null || echo "")
        echo "{\"available\":true,\"authenticated\":true,\"user\":\"$user\",\"message\":\"Azure DevOps ready\"}"
        return 0
    else
        echo '{"available":true,"authenticated":false,"user":null,"message":"Run: az login"}'
        return 1
    fi
}

# Parse Azure repo identifier
# Input: "azure:org/project/repo" or "org/project/repo"
# Output: org project repo (space-separated)
_azure_parse_repo() {
    local input="$1"
    input="${input#azure:}"
    
    # Split by /
    IFS='/' read -r org project repo <<< "$input"
    echo "$org" "$project" "$repo"
}

# List accessible repositories
# Usage: azure_list_repos [org]
azure_list_repos() {
    local org="${1:-}"
    
    if [[ -z "$org" ]]; then
        # List all orgs user has access to
        local orgs
        orgs=$(az devops project list --query "value[].name" -o tsv 2>/dev/null || echo "")
        if [[ -z "$orgs" ]]; then
            echo "[]"
            return 0
        fi
        org=$(echo "$orgs" | head -1)
    fi
    
    # Get all projects
    local projects_url="https://dev.azure.com/${org}/_apis/projects?api-version=7.1"
    local projects
    projects=$(_azure_api "GET" "$projects_url" | jq -r '.value[]? | .name' 2>/dev/null)
    
    local all_repos="[]"
    
    while IFS= read -r project; do
        [[ -z "$project" ]] && continue
        
        local repos_url="https://dev.azure.com/${org}/${project}/_apis/git/repositories?api-version=7.1"
        local repos
        repos=$(_azure_api "GET" "$repos_url")
        
        local parsed
        parsed=$(echo "$repos" | jq --arg org "$org" --arg project "$project" '[.value[]? | {
            id: ("azure:" + $org + "/" + $project + "/" + .name),
            name: .name,
            description: (.project.description // ""),
            default_branch: (.defaultBranch // "refs/heads/main" | sub("refs/heads/"; ""))
        }]' 2>/dev/null || echo "[]")
        
        all_repos=$(echo "$all_repos" | jq --argjson new "$parsed" '. + $new' 2>/dev/null || echo "[]")
    done <<< "$projects"
    
    echo "$all_repos"
}

# Fetch commits for a repo
# Usage: azure_fetch_commits "org/project/repo" [since_date]
azure_fetch_commits() {
    local repo="$1"
    local since="${2:-}"
    
    read -r org project repo_name <<< "$(_azure_parse_repo "$repo")"
    
    local url="https://dev.azure.com/${org}/${project}/_apis/git/repositories/${repo_name}/commits?api-version=7.1"
    [[ -n "$since" ]] && url="${url}&searchCriteria.fromDate=${since}"
    
    _azure_api "GET" "$url" | jq '[.value[]? | {
        sha: .commitId,
        author: .author.name,
        author_email: .author.email,
        message: .comment,
        date: .author.date,
        files_changed: (.changeCounts.Edit // 0)
    }]' 2>/dev/null || echo "[]"
}

# Fetch pull requests
# Usage: azure_fetch_prs "org/project/repo" [state]
# state: active, completed, abandoned, all (default: all)
azure_fetch_prs() {
    local repo="$1"
    local state="${2:-all}"
    
    read -r org project repo_name <<< "$(_azure_parse_repo "$repo")"
    
    local url="https://dev.azure.com/${org}/${project}/_apis/git/repositories/${repo_name}/pullrequests?api-version=7.1"
    
    # Map state parameter
    case "$state" in
        open) url="${url}&searchCriteria.status=active" ;;
        closed) url="${url}&searchCriteria.status=completed" ;;
        all) url="${url}&searchCriteria.status=all" ;;
    esac
    
    _azure_api "GET" "$url" | jq --arg repo_id "azure:${org}/${project}/${repo_name}" '[.value[]? | {
        id: ($repo_id + ":" + (.pullRequestId | tostring)),
        number: .pullRequestId,
        title: .title,
        state: .status,
        author: .createdBy.displayName,
        created_at: .creationDate,
        updated_at: (.closedDate // .creationDate),
        merged_at: (if .status == "completed" then .closedDate else null end),
        reviewers: [.reviewers[]? | .displayName],
        labels: []
    }]' 2>/dev/null || echo "[]"
}

# Fetch work items (issues)
# Usage: azure_fetch_issues "org/project/repo" [state]
azure_fetch_issues() {
    local repo="$1"
    local state="${2:-all}"
    
    read -r org project repo_name <<< "$(_azure_parse_repo "$repo")"
    
    # Azure DevOps work items require WIQL queries
    # For simplicity, return empty array for now
    # Full implementation would require:
    # 1. POST WIQL query to get work item IDs
    # 2. GET work item details for each ID
    echo "[]"
}

# Get repository metadata
# Usage: azure_get_repo "org/project/repo"
azure_get_repo() {
    local repo="$1"
    
    read -r org project repo_name <<< "$(_azure_parse_repo "$repo")"
    
    local url="https://dev.azure.com/${org}/${project}/_apis/git/repositories/${repo_name}?api-version=7.1"
    
    _azure_api "GET" "$url" | jq '{
        name: .name,
        description: (.project.description // ""),
        default_branch: (.defaultBranch // "refs/heads/main" | sub("refs/heads/"; "")),
        visibility: "private",
        last_push: .project.lastUpdateTime
    }' 2>/dev/null || echo "{}"
}

# Normalize Azure DevOps repo identifier
# Input: "azure:org/project/repo" or "https://dev.azure.com/org/project/_git/repo"
# Output: "org/project/repo"
azure_normalize_repo() {
    local input="$1"

    # Remove azure: prefix
    input="${input#azure:}"

    # Remove Azure DevOps URL prefix
    input="${input#https://dev.azure.com/}"
    input="${input#https://}"

    # Remove _git path component
    input="${input/\/_git\//\/}"

    echo "$input"
}
