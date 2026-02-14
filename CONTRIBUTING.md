# Contributing to SyncLayer

Thank you for your interest in contributing to SyncLayer! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:

- **Clear title** - Describe the bug in one sentence
- **Steps to reproduce** - How can we reproduce the issue?
- **Expected behavior** - What should happen?
- **Actual behavior** - What actually happens?
- **Environment** - Flutter version, platform (iOS/Android/Web), device
- **Code sample** - Minimal code that reproduces the issue

### Suggesting Features

We love feature suggestions! Please create an issue with:

- **Use case** - What problem does this solve?
- **Proposed solution** - How would you like it to work?
- **Alternatives** - What other solutions did you consider?
- **Examples** - Code examples of how it would be used

### Pull Requests

We welcome pull requests! Here's how:

1. **Fork the repository**
2. **Create a feature branch** - `git checkout -b feature/my-feature`
3. **Make your changes**
4. **Add tests** - Ensure your changes are tested
5. **Run tests** - `flutter test`
6. **Run analyzer** - `flutter analyze`
7. **Format code** - `dart format .`
8. **Commit** - Use clear commit messages
9. **Push** - `git push origin feature/my-feature`
10. **Create PR** - Open a pull request on GitHub

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` to format your code
- Add documentation comments for public APIs
- Keep functions small and focused
- Write descriptive variable names

### Testing

- Add unit tests for new functionality
- Add integration tests for complex features
- Ensure all tests pass before submitting PR
- Aim for high test coverage

### Commit Messages

Use clear, descriptive commit messages:

```
feat: Add custom conflict resolver support
fix: Fix pull sync timestamp issue
docs: Update README with new examples
test: Add tests for batch operations
chore: Update dependencies
```

Prefixes:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

## Development Setup

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Git

### Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/synclayer.git
cd synclayer

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run analyzer
flutter analyze

# Run example app
cd example/todo_app
flutter run
```

### Project Structure

```
synclayer/
├── lib/
│   ├── conflict/       # Conflict resolution
│   ├── core/          # Core initialization
│   ├── local/         # Local storage (Isar)
│   ├── network/       # Backend adapters
│   ├── sync/          # Sync engine
│   └── utils/         # Utilities
├── test/
│   ├── unit/          # Unit tests
│   ├── integration/   # Integration tests
│   └── performance/   # Performance tests
├── example/           # Example code
└── backend/           # Example backend
```

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Other unprofessional conduct

## Questions?

- **GitHub Issues** - For bugs, features, and questions (use "question" label)
- **Email** - legal@hostspica.com for private matters

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to SyncLayer! 🚀
