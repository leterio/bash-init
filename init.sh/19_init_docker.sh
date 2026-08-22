#!/bin/bash
#
# Docker helpers for interactive shells.

# Require docker. Skip when it is missing so the rest of init can continue.
if ! has_command docker; then
  return 0
fi

#######################################
# Remove unused Docker data (images, containers, volumes, networks).
# Returns:
#   0 when every prune step succeeds, non-zero otherwise.
#######################################
function docker_prune() {
  log_info "Pruning system ..."
  if ! docker system prune -fa; then
    log_error "Failed to prune Docker system"
    return 1
  fi

  log_info "Pruning volumes ..."
  if ! docker volume prune -f; then
    log_error "Failed to prune Docker volumes"
    return 1
  fi

  log_info "Pruning networks ..."
  if ! docker network prune -f; then
    log_error "Failed to prune Docker networks"
    return 1
  fi

  log_success "Done"
}
