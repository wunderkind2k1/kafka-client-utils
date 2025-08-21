# How to Use Kafka Client Utils

This guide provides detailed examples of how to use the Kafka client utilities Docker image and the `kafka-tools.sh` script.

## Prerequisites

- Docker installed and running
- Access to a Kafka cluster
- SSL certificates (if using SSL/TLS)

## Basic Usage

### 1. Building the Image

```bash
# Build the latest version
docker build -t kafka-client-utils:latest .

# Build with specific Kafka version
docker build \
  --build-arg DOWNLOAD_URL=https://dlcdn.apache.org/kafka/4.0.0/kafka_2.13-4.0.0.tgz \
  -t kafka-client-utils:4.0 .
```

### 2. Using the Kafka Tools Script

The `kafka-tools.sh` script provides a convenient wrapper around common Kafka operations.

```bash
# Make executable
chmod +x kafka-tools.sh

# Show help
./kafka-tools.sh help

# List all available commands
./kafka-tools.sh help
```

## Key Examples

Here are three essential examples to get you started:

### 1. Describe a Consumer Group
```bash
./kafka-tools.sh consumer-groups-describe my-consumer-group
```

### 2. Reset Consumer Group Offsets
```bash
# Reset to latest (start from current position)
./kafka-tools.sh consumer-groups-reset-offsets my-group my-topic --to-latest

# Reset to specific time
./kafka-tools.sh consumer-groups-reset-offsets my-group my-topic \
  --to-datetime "2024-01-15T10:00:00Z"
```

### 3. List All Topics
```bash
./kafka-tools.sh topics-list
```

## Available Tools

The following Kafka tools are available in the image and can be used with the script or directly:

### Topic Management
- `kafka-topics.sh` - Create, delete, describe, and list topics
- `kafka-configs.sh` - View and modify topic configurations

### Consumer Group Management
- `kafka-consumer-groups.sh` - List, describe, and reset consumer groups
- `kafka-get-offsets.sh` - Get topic offsets

### Performance Testing
- `kafka-producer-perf-test.sh` - Test producer performance
- `kafka-consumer-perf-test.sh` - Test consumer performance

### Utility Tools
- `kafka-features.sh` - List available Kafka features
- `kafka-broker-api-versions.sh` - Check broker API compatibility

### Direct Usage
All tools can be run directly with Docker:
```bash
docker run --rm -v "$PWD:/work" -w /work kafka-client-utils:latest \
  kafka-topics.sh --bootstrap-server broker:9092 --list
```

## SSL/TLS Configuration

Create a `client.properties` file (never commit this):

```properties
security.protocol=SSL
ssl.keystore.type=PEM
ssl.keystore.location=<path-to>/client-combined.pem
ssl.truststore.type=PEM
ssl.truststore.location=<path-to>/ca-cert.pem
```

## Environment Variables

The Docker container supports several environment variables:

```bash
# Custom JVM heap settings
docker run --rm -e KAFKA_HEAP_OPTS="-Xms512m -Xmx2g" \
  kafka-client-utils:latest kafka-topics.sh --help

# Custom memory limits
docker run --rm --memory=2g kafka-client-utils:latest \
  kafka-topics.sh --help
```

## Troubleshooting

### Common Issues

1. **"No configuration found" error**: This is harmless and appears with `--help` or `--version`
2. **SSL connection issues**: Verify certificate paths and permissions
3. **Permission denied**: Ensure the script is executable (`chmod +x kafka-tools.sh`)

### Debug Mode

For troubleshooting, you can run the Docker container interactively:

```bash
docker run --rm -it -v "$PWD:/work" -w /work kafka-client-utils:latest bash

# Then run Kafka commands directly
kafka-topics.sh --bootstrap-server kafka-broker.example.com:9092 --list
```

## Best Practices

1. **Always use the script** for common operations - it handles paths and configurations
2. **Never commit sensitive files** - add them to `.gitignore`
3. **Use specific image tags** in production for reproducibility
4. **Test with non-production clusters** first
5. **Monitor consumer lag** regularly in production environments
