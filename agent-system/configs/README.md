# DeMoD Agent System Configuration

This directory contains configuration files for different deployment environments of the DeMoD Agent System.

## Configuration Files

### `development.yaml`
Configuration for local development environments.
- Debug logging enabled
- Local database connections
- Relaxed security settings
- Auto-reload enabled

### `staging.yaml`
Configuration for testing/staging environments.
- Production-like settings
- Staging database connections
- Detailed logging for debugging
- Feature flags for testing

### `production.yaml`
Configuration for production deployments.
- Optimized performance settings
- Secure database connections
- Minimal logging (error-level only)
- All security features enabled

### `local.yaml`
Local development overrides.
- Personal development settings
- Local overrides for specific features
- Debug tools and hot reload

## Configuration Structure

Each configuration file follows this structure:

```yaml
# API Configuration
api:
  host: "0.0.0.0"
  port: 8000
  workers: 4
  reload: false  # Only for development

# Database Configuration
database:
  url: "postgresql://user:pass@host:port/dbname"
  pool_size: 10
  max_overflow: 20
  pool_timeout: 30

# Redis Configuration (for caching and sessions)
redis:
  url: "redis://localhost:6379/0"
  max_connections: 10

# Agent Configuration
agents:
  max_agents: 20
  auto_spawn: true
  min_idle_agents: 3
  default_timeout: 600
  max_timeout: 3600

# Security Configuration
security:
  api_key_required: true
  cors_origins: ["http://localhost:3000"]
  rate_limit_per_minute: 60
  allowed_hosts: ["localhost", "127.0.0.1"]

# AgentVM Integration
agentvm:
  api_endpoint: "http://localhost:8000"
  api_key: "${AGENTVM_API_KEY}"  # Environment variable
  default_repo_path: "/mnt/host-projects/current"

# Cloud Provider Configuration
cloud:
  provider: "local"  # local, aws, azure, gcp
  region: "us-west-2"
  
  # AWS specific (if provider = aws)
  aws:
    access_key_id: "${AWS_ACCESS_KEY_ID}"
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
    region: "${AWS_DEFAULT_REGION}"
    
  # Azure specific (if provider = azure)
  azure:
    subscription_id: "${AZURE_SUBSCRIPTION_ID}"
    tenant_id: "${AZURE_TENANT_ID}"
    client_id: "${AZURE_CLIENT_ID}"
    client_secret: "${AZURE_CLIENT_SECRET}"
    
  # GCP specific (if provider = gcp)
  gcp:
    project_id: "${GCP_PROJECT_ID}"
    service_account_key: "${GCP_SERVICE_ACCOUNT_KEY}"

# Monitoring Configuration
monitoring:
  enabled: true
  prometheus:
    enabled: true
    port: 9090
  grafana:
    enabled: true
    port: 3000
    admin_password: "${GRAFANA_ADMIN_PASSWORD}"
    
# Logging Configuration
logging:
  level: "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
  format: "json"  # json, text
  file: "/var/log/agent-system/app.log"
  max_size: "100MB"
  backup_count: 5

# Feature Flags
features:
  websocket_support: true
  task_prioritization: true
  auto_scaling: false
  advanced_metrics: true
```

## Environment Variables

Sensitive values should be stored in environment variables rather than configuration files:

### Required
- `AGENTVM_API_KEY` - API key for AgentVM communication
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string

### Optional (Cloud-specific)
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
- `GCP_PROJECT_ID` - Google Cloud project ID

### Optional (Security)
- `SECRET_KEY` - JWT secret key (auto-generated if not provided)
- `CORS_ORIGINS` - Comma-separated list of allowed origins
- `RATE_LIMIT_PER_MINUTE` - API rate limit per minute

## Usage

### Using Specific Configuration

```bash
# Start with development config
export CONFIG_FILE=development.yaml
python -m uvicorn src.api.main:app --reload

# Start with production config
export CONFIG_FILE=production.yaml
python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8000
```

### Docker Compose

```bash
# Development
docker-compose -f docker-compose.yml --env-file configs/.env.development up

# Production
docker-compose -f docker-compose.yml --env-file configs/.env.production up
```

### Environment-Specific Overrides

Create environment files (`.env.development`, `.env.production`, etc.):

```bash
# .env.development
CONFIG_FILE=development.yaml
DEBUG=true
DATABASE_URL=postgresql://postgres:password@localhost:5432/agent_system_dev
REDIS_URL=redis://localhost:6379/0
AGENTVM_API_KEY=dev-key-2026

# .env.production
CONFIG_FILE=production.yaml
DEBUG=false
DATABASE_URL=postgresql://agent:secure_password@db:5432/agent_system
REDIS_URL=redis://redis:6379/0
AGENTVM_API_KEY=${AGENTVM_API_KEY}  # From secrets manager
```

## Configuration Validation

The system validates configuration on startup:

1. **Required fields** - Must be present and valid
2. **Data types** - Must match expected types
3. **Environment variables** - Must exist if referenced
4. **Network connectivity** - Database/Redis connections tested
5. **File permissions** - Log directories must be writable

## Security Best Practices

1. **Never commit secrets** to configuration files
2. **Use environment variables** for all sensitive data
3. **Restrict file permissions** on configuration files:
   ```bash
   chmod 600 configs/production.yaml
   ```
4. **Validate configurations** before deployment
5. **Use secrets management** (HashiCorp Vault, AWS Secrets Manager) for production

## Testing Configurations

### Test Configuration Syntax

```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('configs/production.yaml'))"

# Test configuration loading
python -m src.core.config --config configs/development.yaml --validate
```

### Test with Mock Services

```bash
# Start with test database
docker run -d --name test-postgres -e POSTGRES_DB=test_db postgres:13
export DATABASE_URL=postgresql://postgres:password@localhost:5432/test_db

# Test configuration loading
python -m src.api.main --config configs/development.yaml --test
```

## Configuration Management

### Version Control

- Keep configurations in version control
- Exclude sensitive environment files (`.env.production`)
- Use template files for sensitive configurations (`.env.production.template`)

### Deployment

Use CI/CD pipelines to:
1. Validate configuration syntax
2. Test configuration with staging environment
3. Deploy with proper environment variables
4. Monitor configuration changes

### Rollback

Maintain previous configuration versions:
```bash
# Backup current config
cp configs/production.yaml configs/production.yaml.backup

# Restore if needed
cp configs/production.yaml.backup configs/production.yaml
```

## Troubleshooting

### Common Configuration Issues

1. **Database connection failed**
   - Check `DATABASE_URL` format
   - Verify database is running
   - Check network connectivity

2. **Redis connection failed**
   - Check `REDIS_URL` format
   - Verify Redis service status
   - Check firewall settings

3. **API key validation failed**
   - Verify `AGENTVM_API_KEY` is set
   - Check AgentVM is accessible
   - Validate key format

4. **Permission denied on log file**
   - Check log directory permissions
   - Verify service user rights
   - Create directory with proper ownership

### Debug Configuration Loading

```bash
# Show loaded configuration
python -m src.core.config --config configs/development.yaml --show

# Validate specific environment
CONFIG_ENV=staging python -m src.core.config --validate
```

For more information, see the main README.md and API documentation.
