# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.0.0](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-08-26
### Added
- **Kafka Tools Script**: Comprehensive `kafka-tools.sh` script for easy Kafka operations
- **SSL/TLS Support**: Full support for secure connections with PEM certificates
- **Consumer Group Management**: Advanced offset reset operations (earliest, latest, time-based, duration-based)
- **Performance Testing**: Built-in producer and consumer performance testing tools
- **Configuration Management**: Topic configuration inspection and modification
- **Comprehensive Documentation**: Detailed HOW-TO-USE.md with real-world examples

### Fixed
- **JVM Memory Issues**: Removed problematic JAVA_TOOL_OPTIONS that caused container startup issues
- **Message Handler Chain**: Fixed consumer message processing and logging
- **Docker Volume Mounting**: Improved path handling for configuration files

### Security
- **Enhanced .gitignore**: Comprehensive protection against committing sensitive files
- **SSL Configuration**: Proper PEM certificate handling for production use

## [0.1.0] - 2025-08-22
### Added
- Multi-stage Dockerfile to build a Kafka client-only image.
  - Downloads Kafka 4.0.0 (override via `DOWNLOAD_URL`).
  - Prunes server-side scripts and ships only client tools.
  - Uses Amazon Corretto JRE 17 on Alpine as runtime.
  - Places Kafka scripts on PATH for direct execution.
- README with build and usage instructions.
- Initial LICENSE placeholder retained from repository.

[0.2.0]: https://github.com/your-org/kafka-client-utils/releases/tag/v0.2.0
[0.1.0]: https://github.com/your-org/kafka-client-utils/releases/tag/v0.1.0
