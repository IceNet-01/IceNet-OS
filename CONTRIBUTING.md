# Contributing to IceNet-OS

Thank you for your interest in contributing to IceNet-OS! This document provides guidelines and information for contributors.

## Code of Conduct

Be respectful, constructive, and professional. We're building an OS together!

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (architecture, version)
   - Relevant logs or screenshots

### Suggesting Features

1. Check existing issues and discussions
2. Create an issue describing:
   - The feature and its benefits
   - Potential implementation approach
   - Any concerns or alternatives considered

### Contributing Code

1. **Fork the repository**
   ```bash
   git clone https://github.com/YourUsername/IceNet-OS.git
   cd IceNet-OS
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clean, readable code
   - Follow existing code style
   - Add comments for complex logic
   - Test your changes thoroughly

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Development Guidelines

### Code Style

#### C Code
- Use K&R style indentation (4 spaces, no tabs)
- Maximum line length: 100 characters
- Function names: `snake_case`
- Constants: `UPPER_CASE`
- Clear, descriptive variable names

Example:
```c
static int process_package(const char *pkg_name) {
    if (!pkg_name) {
        return -1;
    }

    /* Process the package */
    ...
}
```

#### Shell Scripts
- Use `#!/bin/bash` shebang
- Add `set -e` for error handling
- Quote all variables: `"$variable"`
- Use meaningful function names

Example:
```bash
#!/bin/bash
set -e

create_directory() {
    local dir_name="$1"
    mkdir -p "$dir_name"
}
```

### Testing

Before submitting:

1. **Build test all architectures**
   ```bash
   make clean
   make all-images
   ```

2. **Test in QEMU**
   ```bash
   qemu-system-x86_64 -drive file=build-output/icenet-os-x86_64-0.1.0.img
   ```

3. **Test on real hardware** (if possible)

### Documentation

- Update relevant documentation for any changes
- Add comments for non-obvious code
- Update README.md if adding features
- Add to BUILDING.md for build-related changes

### Commit Messages

Use clear, descriptive commit messages:

```
Add ice-pkg support for dependency resolution

- Implement recursive dependency checking
- Add cycle detection
- Update package database schema

Fixes #123
```

Format:
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed description if needed
- Reference issues: `Fixes #123` or `Relates to #456`

## Project Areas

### High Priority

- **Security**: Bug fixes, hardening, security features
- **Hardware Support**: Additional device drivers, platform support
- **Performance**: Optimizations, boot time improvements
- **Documentation**: Guides, examples, tutorials

### Active Development

- **Init System**: Service management improvements
- **Package Manager**: Repository support, dependency resolution
- **Build System**: Automation, cross-compilation improvements
- **Kernel**: Configuration optimization, patches

### Future Goals

- Custom microkernel (long-term)
- Container support
- OTA updates
- GUI environment (optional)

## Getting Help

- Create an issue for questions
- Prefix title with [Question]
- Provide context and what you've tried

## Pull Request Process

1. **Ensure PR is ready**
   - All tests pass
   - Documentation updated
   - Code follows style guidelines
   - Commits are clean and descriptive

2. **PR Description**
   - Clear description of changes
   - Motivation and context
   - Testing performed
   - Screenshots if applicable

3. **Review Process**
   - Maintainers will review
   - Address feedback promptly
   - Make requested changes
   - PR merged when approved

## Development Environment

### Recommended Setup

```bash
# Install development tools
sudo apt-get install build-essential git vim ctags cscope

# Clone repository
git clone https://github.com/IceNet-01/IceNet-OS.git
cd IceNet-OS

# Build development image
cd build
make setup
make ARCH=x86_64 image

# Test in QEMU
qemu-system-x86_64 \
    -drive file=../build-output/icenet-os-x86_64-0.1.0.img,format=raw \
    -m 1024 \
    -enable-kvm
```

### Debugging

#### Init System
```c
/* Add debug prints */
printf("DEBUG: Service %s state=%d\n", svc->name, svc->state);
```

#### Kernel
```bash
# Enable debug output
make ARCH=x86_64 menuconfig
# Enable CONFIG_DEBUG_KERNEL, CONFIG_DEBUG_INFO
```

#### Build System
```bash
# Verbose build
make V=1 kernel
```

## Areas Needing Help

### Documentation
- User guides and tutorials
- API documentation
- Translation to other languages

### Testing
- Testing on different hardware
- Automated testing framework
- Performance benchmarking

### Packages
- Creating packages for common software
- Package build automation
- Repository management

### Hardware Support
- Additional SBC support
- Driver development
- Hardware documentation

## Resources

### Linux Kernel
- https://kernel.org/doc/html/latest/
- https://kernelnewbies.org/

### Init Systems
- https://www.freedesktop.org/wiki/Software/systemd/
- http://smarden.org/runit/
- https://skarnet.org/software/s6/

### Package Management
- https://www.archlinux.org/pacman/
- https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management

### Build Systems
- https://www.gnu.org/software/make/manual/
- https://buildroot.org/
- https://www.yoctoproject.org/

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

Thank you for contributing to IceNet-OS!
