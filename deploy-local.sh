#!/bin/bash

# Local Deployment Helper Script
# Helps with BE integration using local network
# Just run: ./deploy-local.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Config file path
CONFIG_FILE="config/CollectionConfig.ts"
DEPLOYMENT_STATE_FILE="deployments/deployment-state.json"
NODE_PID_FILE=".hardhat-node.pid"
LOCALHOST_CHAIN_ID="1337"
LOCALHOST_DEPLOYMENT_KEY="contractAddress"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
}

print_address() {
    echo -e "${CYAN}$1${NC}"
}

# Function to extract a quoted config value from CollectionConfig.ts
extract_config_value() {
    local key=$1
    local line
    line=$(grep -E "^[[:space:]]*$key:" "$CONFIG_FILE" | head -1 || true)

    if [ -z "$line" ]; then
        echo ""
        return 0
    fi

    if printf '%s\n' "$line" | grep -q "null"; then
        echo ""
        return 0
    fi

    printf '%s\n' "$line" | sed -E 's/.*"([^"]*)".*/\1/'
}

# Function to read the latest deployed localhost contract address from deployment state
get_localhost_deployed_address() {
    if [ ! -f "$DEPLOYMENT_STATE_FILE" ]; then
        echo ""
        return 0
    fi

    node -e '
const fs = require("fs");
const [stateFile, chainId, contractKey] = process.argv.slice(1);
try {
  const state = JSON.parse(fs.readFileSync(stateFile, "utf8"));
  const address = state?.[chainId]?.[contractKey]?.address ?? "";
  process.stdout.write(address);
} catch {
  process.stdout.write("");
}
' "$DEPLOYMENT_STATE_FILE" "$LOCALHOST_CHAIN_ID" "$LOCALHOST_DEPLOYMENT_KEY"
}

# Function to show the latest localhost deployment report path
get_latest_localhost_report() {
    ls -t deployments/localhost-*.md 2>/dev/null | head -1
}

to_lowercase() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Function to check if hardhat node is running
is_node_running() {
    if lsof -i:8545 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to start hardhat node in background
start_node_background() {
    if is_node_running; then
        print_info "Hardhat node already running on port 8545"
        return 0
    fi

    print_info "Starting Hardhat node in background..."
    nohup npx hardhat node > /tmp/hardhat-node.log 2>&1 &
    echo $! > "$NODE_PID_FILE"

    # Wait for node to be ready
    local retries=0
    while ! is_node_running && [ $retries -lt 30 ]; do
        sleep 1
        retries=$((retries + 1))
        echo -ne "\r${GREEN}[INFO]${NC} Waiting for node to start... ${retries}s"
    done
    echo ""

    if is_node_running; then
        # Wait a bit more for node to fully initialize
        sleep 2
        print_info "✅ Hardhat node started successfully (PID: $(cat $NODE_PID_FILE))"
        return 0
    else
        print_error "Failed to start Hardhat node"
        return 1
    fi
}

# Function to stop hardhat node
stop_node() {
    if [ -f "$NODE_PID_FILE" ]; then
        local pid=$(cat "$NODE_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            print_info "Stopping Hardhat node (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            rm -f "$NODE_PID_FILE"
            print_info "Node stopped"
        else
            rm -f "$NODE_PID_FILE"
        fi
    fi

    # Also kill any process on port 8545
    local port_pid=$(lsof -t -i:8545 2>/dev/null || true)
    if [ -n "$port_pid" ]; then
        kill "$port_pid" 2>/dev/null || true
    fi
}

# Function to display localhost deployment details
show_localhost_addresses() {
    local contract_name
    local configured_address
    local deployed_address
    local latest_report

    contract_name=$(extract_config_value "contractName")
    configured_address=$(extract_config_value "local_address")
    deployed_address=$(get_localhost_deployed_address)
    latest_report=$(get_latest_localhost_report)

    print_header "════════════════════════════════════════════════════════════"
    print_header "  📋 Deployed Localhost Contract (for BE Integration)"
    print_header "════════════════════════════════════════════════════════════"
    echo ""

    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BOLD}This project deploys a single localhost contract for backend integration:${NC}"
        echo ""
        echo -e "${BOLD}Contract name:${NC} ${contract_name:-Unknown}"

        if [ -n "$deployed_address" ]; then
            echo -e "${BOLD}Latest deployed contractAddress (chain ${LOCALHOST_CHAIN_ID}):${NC}"
            print_address "    \"$deployed_address\""
        else
            print_warn "No localhost deployment state found in $DEPLOYMENT_STATE_FILE"
        fi

        if [ -n "$configured_address" ]; then
            echo -e "${BOLD}Configured local_address:${NC}"
            print_address "    \"$configured_address\""
        else
            print_warn "CollectionConfig.local_address is empty"
        fi

        if [ -n "$deployed_address" ] && [ -n "$configured_address" ] && [ "$(to_lowercase "$deployed_address")" != "$(to_lowercase "$configured_address")" ]; then
            print_warn "Deployment state and CollectionConfig.local_address are out of sync"
        fi

        if [ -n "$latest_report" ]; then
            echo -e "${BOLD}Latest deployment report:${NC} $latest_report"
        fi

        echo ""
        print_header "════════════════════════════════════════════════════════════"
    else
        print_error "Config file not found: $CONFIG_FILE"
    fi
}

# Function to deploy to localhost and show addresses
deploy_localhost() {
    print_header "════════════════════════════════════════════════════════════"
    print_header "  🚀 Microfinance Local Deployment (Auto Mode)"
    print_header "════════════════════════════════════════════════════════════"
    echo ""

    # Step 1: Stop any existing node first
    stop_node
    sleep 1

    # Step 2: Start node in background for deployment
    start_node_background

    # Step 3: Clear previous deployment state for fresh deploy
    if [ -f "deployments/deployment-state.json" ]; then
        print_info "Clearing previous deployment state..."
        rm -f deployments/deployment-state.json
    fi

    # Step 4: Deploy contracts
    print_info "Deploying contracts..."
    echo ""

    npx hardhat run scripts/0_deploy.ts --network localhost

    echo ""
    print_info "✅ Deployment completed!"
    echo ""

    # Step 5: Show the deployed addresses
    show_localhost_addresses

    # Step 6: Keep node running - wait for Ctrl+C
    echo ""
    print_header "════════════════════════════════════════════════════════════"
    print_info "🟢 Node is running on http://127.0.0.1:8545"
    print_info "📋 Contract deployed and ready for BE integration"
    print_warn "Press Ctrl+C to stop the node"
    print_header "════════════════════════════════════════════════════════════"
    echo ""

    # Trap Ctrl+C to stop the node gracefully
    trap 'echo ""; print_info "Stopping node..."; stop_node; exit 0' INT

    # Wait indefinitely (node runs in background)
    while is_node_running; do
        sleep 5
    done

    print_error "Node stopped unexpectedly"
}

# Function to check if .env exists
check_env() {
    if [ ! -f .env ]; then
        print_error ".env file not found!"
        print_info "Copy .env.example to .env and fill in your values"
        exit 1
    fi
}

# Function to deploy using new system
deploy() {
    local network=$1
    print_header "════════════════════════════════════════"
    print_header "  Deploying to $network (New System)"
    print_header "════════════════════════════════════════"
    npx hardhat run scripts/0_deploy.ts --network "$network"
}

# Function to show deployment state
show_state() {
    if [ -f deployments/deployment-state.json ]; then
        print_info "Current deployment state:"
        if command -v jq &> /dev/null; then
            cat deployments/deployment-state.json | jq '.'
        else
            cat deployments/deployment-state.json
            print_warn "Install 'jq' for better formatting"
        fi
    else
        print_warn "No deployment state found"
        print_info "Deploy contracts first to create state"
    fi
}

# Function to show latest report
show_report() {
    local latest=$(ls -t deployments/*.md 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        print_info "Latest deployment report: $latest"
        echo ""
        cat "$latest"
    else
        print_warn "No deployment reports found"
        print_info "Reports are generated after successful deployments"
    fi
}

# Function to clear deployment state
clear_state() {
    if [ -f deployments/deployment-state.json ]; then
        print_warn "This will clear the deployment state"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm deployments/deployment-state.json
            print_info "Deployment state cleared"
        else
            print_info "Cancelled"
        fi
    else
        print_warn "No deployment state to clear"
    fi
}

# Function to compile contracts
compile() {
    print_info "Compiling contracts..."
    npx hardhat compile
}

# Function to run tests
run_tests() {
    print_info "Running tests..."
    npx hardhat test
}

# Function to start local node
start_node() {
    print_info "Starting local Hardhat node..."
    print_warn "Press Ctrl+C to stop"
    npx hardhat node
}

# Function to show addresses for a network
show_addresses() {
    local network=$1
    if [ -z "$network" ]; then
        print_error "Network not specified"
        print_info "Usage: ./deploy-helper.sh addresses <network>"
        exit 1
    fi

    print_info "Deployed addresses on $network:"
    if [ -f deployments/deployment-state.json ]; then
        if command -v jq &> /dev/null; then
            jq -r ".[\"$network\"] // empty | to_entries[] | \"\(.key): \(.value.address)\"" deployments/deployment-state.json
        else
            grep -A 100 "\"$network\"" deployments/deployment-state.json || print_warn "Network not found in state"
        fi
    else
        print_warn "No deployment state found"
    fi
}

# Main menu
case "$1" in
    deploy|"")
        deploy_localhost
        ;;

    addresses|show)
        show_localhost_addresses
        ;;

    stop)
        stop_node
        ;;

    restart)
        stop_node
        sleep 2
        deploy_localhost
        ;;

    node)
        print_info "Starting local Hardhat node..."
        print_warn "Press Ctrl+C to stop"
        echo ""
        npx hardhat node
        ;;

    compile)
        print_info "Compiling contracts..."
        npx hardhat compile
        ;;

    test)
        print_info "Running tests..."
        npx hardhat test
        ;;

    clean)
        print_info "Cleaning build artifacts..."
        stop_node
        npx hardhat clean
        rm -rf deployments/deployment-state.json
        print_info "Cleaned!"
        ;;

    help|--help|-h)
        print_header "════════════════════════════════════════════════════════════"
        print_header "  Microfinance Local Deployment Helper"
        print_header "════════════════════════════════════════════════════════════"
        echo ""
        echo "Usage: ./deploy-local.sh [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)           Auto: start node + deploy + show addresses"
        echo "  addresses           Show current localhost deployment details"
        echo "  stop                Stop the background Hardhat node"
        echo "  restart             Stop node, then redeploy everything"
        echo "  node                Start Hardhat node in foreground (manual mode)"
        echo "  compile             Compile contracts"
        echo "  test                Run contract tests"
        echo "  clean               Stop node + clean artifacts"
        echo "  help                Show this help message"
        echo ""
        echo "Quick Start for BE Integration:"
        echo "  ${BOLD}./deploy-local.sh${NC}  (that's it!)"
        echo ""
        print_info "Node runs in background, deployment details come from CollectionConfig.ts and deployment-state.json"
        ;;

    *)
        print_error "Unknown command: $1"
        print_info "Use './deploy-local.sh help' to see available commands"
        exit 1
        ;;
esac
