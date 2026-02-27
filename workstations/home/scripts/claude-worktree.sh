#!/usr/bin/env bash
# Claude worktree workflow script
# Manages git worktrees for Claude development workflow

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Usage information
usage() {
	cat <<EOF
Usage: claude-worktree <command> [options]

Commands:
  <name>              Create worktree or checkout existing branch (default command)
  list                List all active worktrees
  close <name>        Remove/delete a worktree

Create Options:
  --from <branch>     Base branch to create worktree from (default: origin/main)
                      Only used when creating a NEW branch
  --no-open          Don't open a new Ghostty window after creation

Branch Behavior:
  The script intelligently handles existing branches:
  - If local branch exists: checks it out
  - If remote branch exists: creates tracking branch
  - If neither exists: creates new branch from --from option (default: origin/main)

Examples:
  cwt my-feature                    # Auto-detect or create, open in Ghostty
  cwt my-feature --from origin/dev  # Create NEW branch from origin/dev
  cwt existing-branch               # Checkout existing branch in worktree
  cwt my-feature --no-open          # Create/checkout without opening Ghostty
  cwt list                          # List all worktrees
  cwt close my-feature              # Remove my-feature worktree
EOF
	exit 1
}

# Get repository root
get_repo_root() {
	local root
	root=$(git rev-parse --show-toplevel 2>/dev/null || true)
	if [[ -z "$root" ]]; then
		log_error "Not in a git repository"
		exit 1
	fi
	echo "$root"
}

# List all worktrees in .claude/worktrees
cmd_list() {
	local repo_root
	repo_root=$(get_repo_root)
	local worktrees_dir="$repo_root/.claude/worktrees"

	if [[ ! -d "$worktrees_dir" ]]; then
		log_info "No worktrees directory found"
		echo "Run 'cwt <name>' to create your first worktree"
		return 0
	fi

	log_info "Active Claude worktrees:"
	echo ""

	# Use git worktree list and filter for .claude/worktrees
	if git worktree list | grep -q ".claude/worktrees"; then
		git worktree list | grep ".claude/worktrees" | while IFS= read -r line; do
			# Extract just the worktree name from the path
			local worktree_path
			worktree_path=$(echo "$line" | awk '{print $1}')
			local worktree_name
			worktree_name=$(basename "$worktree_path")
			local branch
			# Extract branch name from brackets [branch-name]
			branch=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\].*/\1/p')
			[[ -z "$branch" ]] && branch="detached"
			echo -e "  ${BLUE}•${NC} ${GREEN}$worktree_name${NC} ${YELLOW}[$branch]${NC}"
		done
	else
		echo "  No active worktrees found"
	fi

	echo ""
	# Also show directories that might not be tracked by git
	local orphaned=false
	shopt -s nullglob
	for dir in "$worktrees_dir"/*; do
		if [[ -d "$dir" ]]; then
			local dir_name
			dir_name=$(basename "$dir")
			if ! git worktree list | grep -q "$dir_name"; then
				if [[ "$orphaned" == false ]]; then
					log_warn "Orphaned directories (not tracked by git):"
					orphaned=true
				fi
				echo -e "  ${YELLOW}•${NC} $dir_name ${RED}[orphaned - use 'rm -rf' to remove]${NC}"
			fi
		fi
	done
	shopt -u nullglob
}

# Close/remove a worktree
cmd_close() {
	if [[ $# -ne 1 ]]; then
		log_error "Usage: cwt close <name>"
		exit 1
	fi

	local worktree_name="$1"
	local repo_root
	repo_root=$(get_repo_root)
	local worktree_dir="$repo_root/.claude/worktrees/$worktree_name"

	if [[ ! -d "$worktree_dir" ]]; then
		log_error "Worktree '$worktree_name' not found at: $worktree_dir"
		exit 1
	fi

	log_info "Removing worktree: $worktree_name"

	# Check for uncommitted changes
	if git -C "$worktree_dir" diff-index --quiet HEAD 2>/dev/null || ! git -C "$worktree_dir" diff-files --quiet 2>/dev/null; then
		log_warn "Worktree has uncommitted changes that will be discarded"
		read -p "Continue with removal? [y/N] " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_info "Removal cancelled"
			return 0
		fi
	fi

	# Remove the worktree (--force to handle uncommitted changes)
	if git worktree remove "$worktree_dir" --force 2>/dev/null; then
		log_info "Worktree removed successfully"
	else
		# If git worktree remove fails, try manual cleanup
		log_warn "Git worktree remove failed, cleaning up manually..."
		rm -rf "$worktree_dir"
		log_info "Directory removed"
	fi

	# Optionally delete the branch if it exists and matches the worktree name
	if git show-ref --verify --quiet "refs/heads/$worktree_name"; then
		read -p "Delete branch '$worktree_name' as well? [y/N] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			git branch -D "$worktree_name"
			log_info "Branch '$worktree_name' deleted"
		fi
	fi
}

# Detect package manager and install dependencies
install_dependencies() {
	local worktree_dir="$1"

	log_info "Detecting package manager..."

	if [[ -f "$worktree_dir/bun.lockb" ]]; then
		if command -v bun &>/dev/null; then
			log_info "Found bun.lockb, running bun install..."
			bun install
		else
			log_warn "Found bun.lockb but 'bun' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/pnpm-lock.yaml" ]]; then
		if command -v pnpm &>/dev/null; then
			log_info "Found pnpm-lock.yaml, running pnpm install..."
			pnpm install
		else
			log_warn "Found pnpm-lock.yaml but 'pnpm' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/yarn.lock" ]]; then
		if command -v yarn &>/dev/null; then
			log_info "Found yarn.lock, running yarn install..."
			yarn install
		else
			log_warn "Found yarn.lock but 'yarn' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/package-lock.json" ]]; then
		if command -v npm &>/dev/null; then
			log_info "Found package-lock.json, running npm install..."
			npm install
		else
			log_warn "Found package-lock.json but 'npm' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/package.json" ]]; then
		if command -v npm &>/dev/null; then
			log_warn "Found package.json but no lockfile, running npm install..."
			npm install
		else
			log_warn "Found package.json but 'npm' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/Cargo.lock" ]]; then
		if command -v cargo &>/dev/null; then
			log_info "Found Cargo.lock, running cargo fetch..."
			cargo fetch
		else
			log_warn "Found Cargo.lock but 'cargo' command not found, skipping fetch"
		fi
	elif [[ -f "$worktree_dir/go.mod" ]]; then
		if command -v go &>/dev/null; then
			log_info "Found go.mod, running go mod download..."
			go mod download
		else
			log_warn "Found go.mod but 'go' command not found, skipping download"
		fi
	elif [[ -f "$worktree_dir/requirements.txt" ]]; then
		if command -v pip &>/dev/null; then
			log_warn "Found requirements.txt, running pip install (consider using a virtualenv)..."
			pip install -r requirements.txt
		else
			log_warn "Found requirements.txt but 'pip' command not found, skipping install"
		fi
	elif [[ -f "$worktree_dir/Pipfile.lock" ]]; then
		if command -v pipenv &>/dev/null; then
			log_info "Found Pipfile.lock, running pipenv install..."
			pipenv install
		else
			log_warn "Found Pipfile.lock but 'pipenv' command not found, skipping install"
		fi
	else
		log_warn "No recognized package manager lockfile found"
	fi
}

# Open Ghostty window
open_ghostty() {
	local worktree_dir="$1"

	if command -v ghostty &>/dev/null; then
		log_info "Opening new Ghostty window..."
		if [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS: Use open command to launch Ghostty
			open -na Ghostty --args --working-directory="$worktree_dir" --window-save-state=never
		else
			# Linux: Launch Ghostty directly in background
			nohup ghostty --working-directory="$worktree_dir" &>/dev/null &
		fi
		echo -e "${GREEN}New Ghostty window opened${NC}"
	else
		log_warn "Ghostty not found, skipping window open"
		echo -e "${GREEN}Command to enter:${NC} cd $worktree_dir"
	fi
}

# Create a new worktree
cmd_create() {
	local worktree_name=""
	local base_branch="origin/main"
	local open_ghostty=true

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		--from)
			base_branch="$2"
			shift 2
			;;
		--no-open)
			open_ghostty=false
			shift
			;;
		-*)
			log_error "Unknown option: $1"
			usage
			;;
		*)
			if [ -z "$worktree_name" ]; then
				worktree_name="$1"
			else
				log_error "Too many arguments"
				usage
			fi
			shift
			;;
		esac
	done

	# Validate worktree name
	if [[ -z "$worktree_name" ]]; then
		log_error "Worktree name is required"
		usage
	fi

	local repo_root
	repo_root=$(get_repo_root)
	local worktree_dir="$repo_root/.claude/worktrees/$worktree_name"

	# Check if worktree already exists
	if [[ -d "$worktree_dir" ]]; then
		log_error "Worktree directory already exists: $worktree_dir"
		exit 1
	fi

	# Create .claude/worktrees directory if it doesn't exist
	log_info "Creating .claude/worktrees directory..."
	mkdir -p "$repo_root/.claude/worktrees"

	# Fetch latest changes from origin
	log_info "Fetching latest changes from origin..."
	git fetch origin || log_warn "Failed to fetch from origin, continuing anyway..."

	# Check if branch already exists (local or remote)
	local branch_exists_local=false
	local branch_exists_remote=false

	if git show-ref --verify --quiet "refs/heads/$worktree_name"; then
		branch_exists_local=true
		log_info "Found existing local branch: $worktree_name"
	elif git show-ref --verify --quiet "refs/remotes/origin/$worktree_name"; then
		branch_exists_remote=true
		log_info "Found existing remote branch: origin/$worktree_name"
	fi

	# Create the worktree, either from existing branch or create new
	if [[ "$branch_exists_local" == true ]]; then
		log_info "Checking out existing local branch '$worktree_name'..."
		git worktree add "$worktree_dir" "$worktree_name"
	elif [[ "$branch_exists_remote" == true ]]; then
		log_info "Creating local tracking branch for 'origin/$worktree_name'..."
		git worktree add "$worktree_dir" -b "$worktree_name" "origin/$worktree_name"
	else
		log_info "Creating new branch '$worktree_name' from $base_branch..."
		git worktree add -b "$worktree_name" "$worktree_dir" "$base_branch"
	fi

	# Copy .env files recursively (preserving directory structure)
	log_info "Looking for .env files to copy..."
	local env_found=false
	while IFS= read -r -d '' env_file; do
		local rel_path="${env_file#$repo_root/}"
		mkdir -p "$(dirname "$worktree_dir/$rel_path")"
		cp "$env_file" "$worktree_dir/$rel_path"
		log_info "  Copied $rel_path"
		env_found=true
	done < <(find "$repo_root" \
		-path "$repo_root/.git" -prune -o \
		-path "$repo_root/.claude/worktrees" -prune -o \
		-path "*/node_modules" -prune -o \
		\( -name ".env" -o -name ".env.*" \) -type f -print0)
	if [[ "$env_found" == false ]]; then
		log_warn "No .env files found"
	fi

	# Copy .claude local settings (pre-approved commands, etc.)
	if [[ -f "$repo_root/.claude/settings.local.json" ]]; then
		log_info "Copying .claude/settings.local.json..."
		mkdir -p "$worktree_dir/.claude"
		cp "$repo_root/.claude/settings.local.json" "$worktree_dir/.claude/"
	fi
	if [[ -f "$repo_root/CLAUDE.local.md" ]]; then
		log_info "Copying CLAUDE.local.md..."
		cp "$repo_root/CLAUDE.local.md" "$worktree_dir/"
	fi

	# Change to worktree directory for package installation
	cd "$worktree_dir"

	# Install dependencies
	install_dependencies "$worktree_dir"

	echo ""
	log_info "Worktree created successfully!"
	echo -e "${GREEN}Location:${NC} $worktree_dir"
	echo -e "${GREEN}Branch:${NC} $worktree_name"

	if [[ "$branch_exists_local" == true ]]; then
		echo -e "${BLUE}Status:${NC} Checked out existing local branch"
	elif [[ "$branch_exists_remote" == true ]]; then
		echo -e "${BLUE}Status:${NC} Checked out existing remote branch (now tracking)"
	else
		echo -e "${BLUE}Status:${NC} Created new branch from $base_branch"
	fi

	# Open Ghostty if requested
	if [[ "$open_ghostty" == true ]]; then
		open_ghostty "$worktree_dir"
	else
		echo -e "${GREEN}Command to enter:${NC} cd $worktree_dir"
	fi
}

# Main command dispatcher
main() {
	if [[ $# -eq 0 ]]; then
		usage
	fi

	local command="$1"
	shift

	case "$command" in
	list | ls)
		cmd_list "$@"
		;;
	close | remove | rm)
		cmd_close "$@"
		;;
	help | --help | -h)
		usage
		;;
	-*)
		# Options without command, treat as create
		cmd_create "$command" "$@"
		;;
	*)
		# Default to create command
		cmd_create "$command" "$@"
		;;
	esac
}

main "$@"
