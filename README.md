# kafka-client-utils

A minimal Docker image with only Apache Kafka client tools (no brokers, no ZooKeeper). Handy for topic admin, consumer group inspection, config changes, perf tests, etc.

**Features:**
- 🐳 Lightweight Docker image with Kafka 4.0 client tools
- 🚀 Easy-to-use script for common Kafka operations
- 🔒 SSL/TLS support for secure connections
- 📚 Comprehensive examples and documentation
- 📦 **Significantly smaller** than full Kafka distribution

## Image features
- Kafka 4.0 client tools from the official distribution
- Optimized runtime (Alpine + Corretto JRE 17 + minimal shell tools)
- No server components; only `bin/*.sh` scripts and required libraries
- Tools available directly on PATH (e.g. `kafka-topics.sh`)
- Interactive shell access for debugging and development
- Proper signal handling with tini init system

## Image Size Comparison

This client-only image prioritizes **functional benefits** over size reduction:

| Image Type | Size | Components |
|------------|------|------------|
| **kafka-client-utils** | ~429MB | Client tools + JRE + shell utilities |
| **Official Apache Kafka** | ~388MB | Server + ZK + All tools + JRE |

**Benefits of the client-only image:**
- **Security** - No server components that could be exploited
- **Functionality** - Only the tools you need, no unnecessary server processes
- **Development** - Perfect for CI/CD and development environments with shell access
- **Maintenance** - Easier to manage without server dependencies
- **Debugging** - Interactive shell for troubleshooting and development

*Note: While slightly larger than the full Kafka image, this client-only version provides a focused, secure, and developer-friendly environment for Kafka administration tasks.*

## Quick Start

### Building the Image

Use an explicit Kafka download URL or let the build pick the best default.

- Use the latest Apache CDN by default:
```bash
docker build -t kafka-client-utils:latest .
```

- Pin or override with `DOWNLOAD_URL` (e.g., a mirror or internal cache):
```bash
docker build \
  --build-arg DOWNLOAD_URL=https://dlcdn.apache.org/kafka/4.0.0/kafka_2.13-4.0.0.tgz \
  -t kafka-client-utils:4.0 .
```

### Using the Kafka Tools Script

The repository includes a convenient script `kafka-tools.sh` that wraps common Kafka operations:

```bash
# Make it executable
chmod +x kafka-tools.sh

# List available commands
./kafka-tools.sh help

# List topics
./kafka-tools.sh topics-list

# Describe a topic
./kafka-tools.sh topics-describe my-topic
```

## Usage

### Direct Docker Commands

Run tools directly:
```bash
docker run --rm kafka-client-utils:latest kafka-topics.sh --help
```

Most tools require a `--bootstrap-server`. See [HOW-TO-USE.md](HOW-TO-USE.md) for detailed examples.

### Configuration Files

For SSL/TLS connections, you'll need to create a `client.properties` file. **Never commit this file** - it contains sensitive connection details.

#### Creating Combined PEM Files

Kafka requires a combined PEM file containing both the client certificate and private key. Here's how to create it:

```bash
# 1. Try the standard approach first (usually works)
cat client-cert.pem private-key.pem > combined.pem

# 2. If you get key format errors, convert to PKCS8 format
openssl pkcs8 -topk8 -nocrypt -in private-key.pem -out private-key-pkcs8.pem
cat client-cert.pem private-key-pkcs8.pem > combined.pem
```

**Note:** Start with the standard approach. Only use PKCS8 conversion if you encounter key format errors.

#### SSL Configuration Structure

```properties
security.protocol=SSL
ssl.keystore.type=PEM
ssl.keystore.location=/work/crypto/combined.pem
ssl.truststore.type=PEM
ssl.truststore.location=/work/crypto/ca-cert.pem
```

**Important:**
- Add `client.properties` and your crypto files to `.gitignore` to prevent accidental commits
- Use the template file `client.properties.template` as a starting point
- Ensure proper file permissions on your certificate files

## Included tools
Commonly used scripts included (non-exhaustive):
- kafka-topics.sh
- kafka-console-producer.sh
- kafka-console-consumer.sh
- kafka-consumer-groups.sh
- kafka-configs.sh
- kafka-reassign-partitions.sh
- kafka-leader-election.sh
- kafka-broker-api-versions.sh
- kafka-producer-perf-test.sh
- kafka-consumer-perf-test.sh
- kafka-get-offsets.sh
- kafka-features.sh
- kafka-run-class.sh (required by all scripts)

Server-related scripts (e.g., `kafka-server-start.sh`, ZooKeeper, Connect, MirrorMaker) are intentionally removed.

## Official Documentation

For complete tool documentation and advanced options, refer to the official Apache Kafka documentation:

- **[Kafka Tools Documentation](https://kafka.apache.org/documentation/#tools)** - Complete reference for all command-line tools
- **[Kafka Security Documentation](https://kafka.apache.org/documentation/#security)** - SSL/TLS, SASL, and authentication setup
- **[Kafka Configuration](https://kafka.apache.org/documentation/#configuration)** - All available configuration options
- **[Kafka Operations](https://kafka.apache.org/documentation/#operations)** - Production deployment and monitoring

## Troubleshooting

### Common Issues

- **"No configuration found" error**: This harmless error appears with `--help` or `--version` commands and can be ignored
- **Permission denied**: Ensure the `kafka-tools.sh` script is executable (`chmod +x kafka-tools.sh`)
- **SSL connection issues**: Verify certificate paths and file permissions in your `client.properties`

### Getting Help

- Check the [HOW-TO-USE.md](HOW-TO-USE.md) for detailed examples
- Refer to [Official Kafka Documentation](#official-documentation) for complete tool reference
- Use `./kafka-tools.sh help` to see all available commands

## Notes
- Requires a reachable Kafka cluster when executing operations.
- The error line starting with `main ERROR Reconfiguration failed:` may appear when printing `--help` or `--version`. It is harmless.

## License
Apache Kafka is licensed under the Apache License, Version 2.0. See `LICENSE`.
