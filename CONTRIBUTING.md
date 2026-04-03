# Contributing to stalwart-helm

Thank you for your interest in contributing!

## Development Setup

1. **Prerequisites**: `helm`, `just`
2. **Clone**: `git clone https://github.com/an0nfunc/stalwart-helm.git`
3. **Lint**: `just lint`
4. **Template**: `just template`

## Running Tests

```bash
just test
```

Requires [kubeconform](https://github.com/yannh/kubeconform) for manifest validation.

## Pull Request Process

1. Fork the repository and create a feature branch from `main`.
2. Ensure `just lint` and `just test` pass.
3. Write a clear commit message using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, etc.).
4. Open a PR against `main` with a description of what and why.
5. Address review feedback.

## Reporting Issues

Open an issue on GitHub with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Chart version and Kubernetes version
