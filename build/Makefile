# IceNet-OS Build System
# Main Makefile

# Project Information
PROJECT = IceNet-OS
VERSION = 0.1.0
RELEASE_NAME = arctic-dawn

# Build Configuration
BUILD_DIR = $(CURDIR)/../build-output
CACHE_DIR = $(CURDIR)/../build-cache
ROOTFS_DIR = $(BUILD_DIR)/rootfs
KERNEL_DIR = $(CURDIR)/../kernel

# Architecture Support
ARCH ?= x86_64
SUPPORTED_ARCHS = x86_64 aarch64 armv7

# Cross-compilation toolchains
CROSS_COMPILE_AARCH64 = aarch64-linux-gnu-
CROSS_COMPILE_ARMV7 = arm-linux-gnueabihf-
CROSS_COMPILE_X86_64 =

# Kernel Configuration
KERNEL_VERSION = 6.6.0
KERNEL_SOURCE = linux-$(KERNEL_VERSION)
KERNEL_URL = https://cdn.kernel.org/pub/linux/kernel/v6.x/$(KERNEL_SOURCE).tar.xz

# Compiler Flags
CFLAGS_COMMON = -O2 -pipe -Wall -Wextra
CFLAGS_X86_64 = $(CFLAGS_COMMON) -march=x86-64-v2
CFLAGS_AARCH64 = $(CFLAGS_COMMON) -march=armv8-a
CFLAGS_ARMV7 = $(CFLAGS_COMMON) -march=armv7-a -mfpu=neon-vfpv4

# Colors for output
COLOR_RESET = \033[0m
COLOR_BOLD = \033[1m
COLOR_GREEN = \033[32m
COLOR_BLUE = \033[34m
COLOR_YELLOW = \033[33m

# Default target
.PHONY: all
all: help

.PHONY: help
help:
	@echo "$(COLOR_BOLD)IceNet-OS Build System$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BLUE)Available targets:$(COLOR_RESET)"
	@echo "  $(COLOR_GREEN)setup$(COLOR_RESET)          - Initial build environment setup"
	@echo "  $(COLOR_GREEN)kernel$(COLOR_RESET)         - Build kernel for target architecture"
	@echo "  $(COLOR_GREEN)init$(COLOR_RESET)           - Build custom init system"
	@echo "  $(COLOR_GREEN)core$(COLOR_RESET)           - Build core system utilities"
	@echo "  $(COLOR_GREEN)rootfs$(COLOR_RESET)         - Create root filesystem"
	@echo "  $(COLOR_GREEN)image$(COLOR_RESET)          - Create bootable image"
	@echo "  $(COLOR_GREEN)all-images$(COLOR_RESET)     - Build images for all architectures"
	@echo "  $(COLOR_GREEN)clean$(COLOR_RESET)          - Clean build artifacts"
	@echo "  $(COLOR_GREEN)distclean$(COLOR_RESET)      - Clean everything including cache"
	@echo ""
	@echo "$(COLOR_BLUE)Architecture selection:$(COLOR_RESET)"
	@echo "  make kernel ARCH=x86_64    - Build for Zima boards"
	@echo "  make kernel ARCH=aarch64   - Build for Raspberry Pi 3/4/5 (64-bit)"
	@echo "  make kernel ARCH=armv7     - Build for Raspberry Pi 2/3 (32-bit)"
	@echo ""
	@echo "$(COLOR_BLUE)Current configuration:$(COLOR_RESET)"
	@echo "  Architecture: $(COLOR_YELLOW)$(ARCH)$(COLOR_RESET)"
	@echo "  Version:      $(COLOR_YELLOW)$(VERSION)$(COLOR_RESET)"

.PHONY: setup
setup:
	@echo "$(COLOR_BOLD)Setting up build environment...$(COLOR_RESET)"
	@mkdir -p $(BUILD_DIR) $(CACHE_DIR) $(ROOTFS_DIR)
	@echo "$(COLOR_GREEN)✓ Build directories created$(COLOR_RESET)"
	@echo "Checking for required tools..."
	@command -v gcc >/dev/null 2>&1 || (echo "$(COLOR_YELLOW)⚠ gcc not found$(COLOR_RESET)" && exit 1)
	@command -v make >/dev/null 2>&1 || (echo "$(COLOR_YELLOW)⚠ make not found$(COLOR_RESET)" && exit 1)
	@echo "$(COLOR_GREEN)✓ Build tools verified$(COLOR_RESET)"

.PHONY: download-kernel
download-kernel:
	@echo "$(COLOR_BOLD)Downloading kernel source...$(COLOR_RESET)"
	@mkdir -p $(CACHE_DIR)
	@if [ ! -f $(CACHE_DIR)/$(KERNEL_SOURCE).tar.xz ]; then \
		echo "Downloading Linux $(KERNEL_VERSION)..."; \
		wget -O $(CACHE_DIR)/$(KERNEL_SOURCE).tar.xz $(KERNEL_URL) || \
		curl -L -o $(CACHE_DIR)/$(KERNEL_SOURCE).tar.xz $(KERNEL_URL); \
	else \
		echo "$(COLOR_GREEN)✓ Kernel source already cached$(COLOR_RESET)"; \
	fi

.PHONY: extract-kernel
extract-kernel: download-kernel
	@echo "$(COLOR_BOLD)Extracting kernel source...$(COLOR_RESET)"
	@if [ ! -d $(BUILD_DIR)/$(KERNEL_SOURCE) ]; then \
		tar -xf $(CACHE_DIR)/$(KERNEL_SOURCE).tar.xz -C $(BUILD_DIR); \
		echo "$(COLOR_GREEN)✓ Kernel source extracted$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_GREEN)✓ Kernel source already extracted$(COLOR_RESET)"; \
	fi

.PHONY: kernel-config
kernel-config: extract-kernel
	@echo "$(COLOR_BOLD)Configuring kernel for $(ARCH)...$(COLOR_RESET)"
	@cp $(KERNEL_DIR)/config-$(ARCH) $(BUILD_DIR)/$(KERNEL_SOURCE)/.config
	@$(MAKE) -C $(BUILD_DIR)/$(KERNEL_SOURCE) ARCH=$(ARCH) olddefconfig
	@echo "$(COLOR_GREEN)✓ Kernel configured$(COLOR_RESET)"

.PHONY: kernel
kernel: setup kernel-config
	@echo "$(COLOR_BOLD)Building kernel for $(ARCH)...$(COLOR_RESET)"
	@$(MAKE) -C $(BUILD_DIR)/$(KERNEL_SOURCE) ARCH=$(ARCH) -j$$(nproc)
	@echo "$(COLOR_GREEN)✓ Kernel built successfully$(COLOR_RESET)"

.PHONY: init
init: setup
	@echo "$(COLOR_BOLD)Building icenet-init...$(COLOR_RESET)"
	@$(MAKE) -C ../init ARCH=$(ARCH)
	@echo "$(COLOR_GREEN)✓ Init system built$(COLOR_RESET)"

.PHONY: core
core: setup
	@echo "$(COLOR_BOLD)Building core utilities...$(COLOR_RESET)"
	@$(MAKE) -C ../core ARCH=$(ARCH)
	@echo "$(COLOR_GREEN)✓ Core utilities built$(COLOR_RESET)"

.PHONY: rootfs
rootfs: setup
	@echo "$(COLOR_BOLD)Creating root filesystem...$(COLOR_RESET)"
	@bash scripts/create-rootfs.sh $(ARCH) $(ROOTFS_DIR)
	@echo "$(COLOR_GREEN)✓ Root filesystem created$(COLOR_RESET)"

.PHONY: image
image: kernel init core rootfs
	@echo "$(COLOR_BOLD)Creating bootable image for $(ARCH)...$(COLOR_RESET)"
	@bash scripts/create-image.sh $(ARCH) $(BUILD_DIR)
	@echo "$(COLOR_GREEN)✓ Image created: $(BUILD_DIR)/icenet-os-$(ARCH)-$(VERSION).img$(COLOR_RESET)"

.PHONY: all-images
all-images:
	@for arch in $(SUPPORTED_ARCHS); do \
		echo "$(COLOR_BOLD)Building for $$arch...$(COLOR_RESET)"; \
		$(MAKE) image ARCH=$$arch; \
	done

.PHONY: clean
clean:
	@echo "$(COLOR_BOLD)Cleaning build artifacts...$(COLOR_RESET)"
	@rm -rf $(BUILD_DIR)
	@$(MAKE) -C ../init clean 2>/dev/null || true
	@$(MAKE) -C ../core clean 2>/dev/null || true
	@echo "$(COLOR_GREEN)✓ Clean complete$(COLOR_RESET)"

.PHONY: distclean
distclean: clean
	@echo "$(COLOR_BOLD)Cleaning cache...$(COLOR_RESET)"
	@rm -rf $(CACHE_DIR)
	@echo "$(COLOR_GREEN)✓ All build files removed$(COLOR_RESET)"

.PHONY: info
info:
	@echo "$(COLOR_BOLD)Build Information$(COLOR_RESET)"
	@echo "Project:        $(PROJECT)"
	@echo "Version:        $(VERSION)"
	@echo "Release:        $(RELEASE_NAME)"
	@echo "Architecture:   $(ARCH)"
	@echo "Build Dir:      $(BUILD_DIR)"
	@echo "Cache Dir:      $(CACHE_DIR)"
	@echo "Kernel Version: $(KERNEL_VERSION)"
