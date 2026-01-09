# Environment-Specific Configuration Templates

This directory contains configuration templates for different environments.

## Files

- `parameters.json` - Active configuration (git-ignored for security)
- `parameters.example.json` - Example configuration with sample values
- `parameters.dev.json` - Development environment template
- `parameters.prod.json` - Production environment template

## Usage

1. Copy the appropriate template to `parameters.json`:
   ```bash
   cp config/parameters.dev.json config/parameters.json
   ```

2. Edit `parameters.json` with your actual values

3. Never commit `parameters.json` to git (it's in .gitignore)

## Security Notes

- Store sensitive data in GitHub Secrets, not in these files
- Use environment-specific configurations for different stages
- Connection strings should always be stored in GitHub Secrets
- Review files before committing to ensure no secrets are included
