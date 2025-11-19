#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
UPDATE_INPUT=""
HOSTNAME=$(hostname)
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --input)
      UPDATE_INPUT="$2"
      shift 2
      ;;
    --host)
      HOSTNAME="$2"
      shift 2
      ;;
    -h|--help)
      SHOW_HELP=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$SHOW_HELP" = true ]; then
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Preview what packages would change after updating flake inputs."
  echo ""
  echo "Options:"
  echo "  --input <name>    Update only specific input (e.g., nixpkgs)"
  echo "  --host <hostname> Specify hostname/configuration name"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                          # Update all inputs"
  echo "  $0 --input nixpkgs          # Update only nixpkgs"
  echo "  $0 --host nixlab            # Preview for specific host"
  exit 0
fi

# Determine the build target based on hostname
case "$HOSTNAME" in
  "Colins-MacBook-Pro-3")
    TARGET=".#darwinConfigurations.${HOSTNAME}.system"
    ;;
  "nixos-wsl"|"nixlab"|"greenix")
    TARGET=".#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"
    ;;
  *)
    echo -e "${YELLOW}Warning: Unknown hostname '${HOSTNAME}'${NC}"
    echo "Available configurations:"
    echo "  NixOS: nixos-wsl, nixlab, greenix"
    echo "  Darwin: Colins-MacBook-Pro-3"
    echo ""
    echo "Use --host <name> to specify configuration"
    exit 1
    ;;
esac

echo -e "${GREEN}Preview mode: Checking package changes for ${HOSTNAME}${NC}"
echo ""

# Check if nvd is available
if ! command -v nvd &> /dev/null; then
  echo -e "${RED}Error: nvd is not installed${NC}"
  echo "Install it with: nix profile install nixpkgs#nvd"
  echo "Or add it to your system packages"
  exit 1
fi

# Check if /run/current-system exists
if [ ! -e /run/current-system ]; then
  echo -e "${RED}Error: /run/current-system not found${NC}"
  echo "This script needs to compare against your current system."
  exit 1
fi

# Backup the current flake.lock
echo -e "${YELLOW}Backing up flake.lock...${NC}"
cp flake.lock flake.lock.old

# Update flake
echo -e "${YELLOW}Updating flake inputs...${NC}"
if [ -n "$UPDATE_INPUT" ]; then
  echo "  Updating only: $UPDATE_INPUT"
  nix flake lock --update-input "$UPDATE_INPUT"
else
  echo "  Updating all inputs"
  nix flake update
fi

# Save the new flake.lock
echo -e "${YELLOW}Saving new flake.lock...${NC}"
cp flake.lock flake.lock.new

# Build new system
echo -e "${YELLOW}Building new system configuration...${NC}"
nix build "$TARGET" -o result-preview

# Show the diff
echo ""
echo -e "${GREEN}=== Package Changes ===${NC}"
echo ""
nvd diff /run/current-system result-preview

# Restore the original flake.lock
echo ""
echo -e "${YELLOW}Restoring original flake.lock...${NC}"
mv flake.lock.old flake.lock

echo ""
echo -e "${GREEN}Done! Preview complete.${NC}"
echo ""
echo -e "${YELLOW}Saved files:${NC}"
echo "  - flake.lock.new  (updated lock file)"
echo "  - result-preview  (pre-built system)"
echo ""
echo -e "${YELLOW}To apply these changes (using pre-built system):${NC}"
case "$HOSTNAME" in
  "Colins-MacBook-Pro-3")
    echo "  mv flake.lock.new flake.lock"
    echo "  ./result-preview/activate"
    ;;
  *)
    echo "  mv flake.lock.new flake.lock"
    echo "  sudo result-preview/bin/switch-to-configuration switch"
    ;;
esac
echo ""
echo -e "${YELLOW}Or rebuild normally:${NC}"
if [ -n "$UPDATE_INPUT" ]; then
  echo "  nix flake lock --update-input $UPDATE_INPUT"
else
  echo "  nix flake update"
fi
echo "  sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo ""
echo -e "${YELLOW}To discard:${NC}"
echo "  rm -f flake.lock.new result-preview"
