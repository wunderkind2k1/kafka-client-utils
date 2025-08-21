#! /usr/bin/env bash

# Kafka Tools Script for AWS MSK
# Usage: ./kafka-tools.sh <command> [additional-args]

set -e

# Configuration
BROKER="b-3-public.vwcnsdpeupreprodcnsbro.sheiq8.c2.kafka.eu-west-1.amazonaws.com:9194"
CONFIG_FILE="client.properties"
IMAGE_NAME="kafka-client-utils:latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to run docker command
run_kafka_tool() {
    local tool="$1"
    shift
    local args="$@"

    echo -e "${BLUE}Running: ${tool}${NC}"
    echo -e "${YELLOW}Command: docker run --rm -v \"\$PWD:/work\" -w /work ${IMAGE_NAME} ${tool} --bootstrap-server ${BROKER} --command-config ${CONFIG_FILE} ${args}${NC}"
    echo "---"

    docker run --rm -v "$PWD:/work" -w /work "${IMAGE_NAME}" "${tool}" \
        --bootstrap-server "${BROKER}" \
        --command-config "${CONFIG_FILE}" \
        "$@"
}

# Check if required files exist
check_prerequisites() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo -e "${RED}Error: ${CONFIG_FILE} not found!${NC}"
        exit 1
    fi

    if [[ ! -d "crypto" ]]; then
        echo -e "${RED}Error: crypto/ directory not found!${NC}"
        exit 1
    fi

    if [[ ! -f "crypto/kafka_combined.pem" ]]; then
        echo -e "${RED}Error: crypto/kafka_combined.pem not found!${NC}"
        exit 1
    fi

    if [[ ! -f "crypto/AmazonRootCA1.pem" ]]; then
        echo -e "${RED}Error: crypto/AmazonRootCA1.pem not found!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Prerequisites check passed${NC}"
}

# Show usage
show_usage() {
    echo -e "${BLUE}Kafka Tools Script for AWS MSK${NC}"
    echo ""
    echo "Usage: $0 <command> [additional-args]"
    echo ""
    echo "Available commands:"
    echo "  topics-list                    - List all topics"
    echo "  topics-describe <topic>        - Describe a specific topic"
    echo "  topics-create <topic> [partitions] [replicas] - Create a new topic"
    echo "  topics-delete <topic>          - Delete a topic"
    echo "  consumer-groups-list           - List all consumer groups"
    echo "  consumer-groups-describe <group> - Describe a consumer group"
    echo "  consumer-groups-reset-offsets <group> <topic> [options] - Reset offsets for a consumer group"
    echo "  consumer-groups-describe-topic <group> <topic> - Describe a consumer group filtered by topic (shows only specified topic partitions)"
    echo "  producer-perf-test <topic>     - Run producer performance test"
    echo "  consumer-perf-test <topic>     - Run consumer performance test"
    echo "  configs-describe <topic>       - Describe topic configurations"
    echo "  configs-alter <topic> <key=value> - Alter topic configuration"
    echo "  offsets-get <topic>            - Get topic offsets"
    echo "  features-list                  - List Kafka features"
    echo "  help                           - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 topics-list"
    echo "  $0 topics-describe my-topic"
    echo "  $0 topics-create test-topic 3 2"
    echo "  $0 consumer-groups-list"
    echo "  $0 consumer-groups-reset-offsets my-group my-topic --to-earliest"
    echo "  $0 consumer-groups-describe-topic my-group my-topic"
    echo ""
}

# Main command handling
case "${1:-help}" in
    "topics-list")
        check_prerequisites
        run_kafka_tool "kafka-topics.sh" "--list"
        ;;
    "topics-describe")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 topics-describe <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-topics.sh" "--describe" "--topic" "$2"
        ;;
    "topics-create")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 topics-create <topic> [partitions] [replicas]"
            exit 1
        fi
        local partitions="${3:-3}"
        local replicas="${4:-2}"
        check_prerequisites
        run_kafka_tool "kafka-topics.sh" "--create" "--topic" "$2" "--partitions" "$partitions" "--replication-factor" "$replicas"
        ;;
    "topics-delete")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 topics-delete <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-topics.sh" "--delete" "--topic" "$2"
        ;;
    "consumer-groups-list")
        check_prerequisites
        run_kafka_tool "kafka-consumer-groups.sh" "--list"
        ;;
    "consumer-groups-describe")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Consumer group name required${NC}"
            echo "Usage: $0 consumer-groups-describe <group>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-consumer-groups.sh" "--describe" "--group" "$2"
        ;;
        "consumer-groups-reset-offsets")
        if [[ -z "$2" ]] || [[ -z "$3" ]]; then
            echo -e "${RED}Error: Consumer group name and topic required${NC}"
            echo "Usage: $0 consumer-groups-reset-offsets <group> <topic> [--to-earliest|--to-latest|--to-datetime <datetime>|--by-duration <duration>]"
            exit 1
        fi
        group="$2"
        topic="$3"
        shift 3
        reset_args="$@"

        # Default to --to-earliest if no reset option specified
        if [[ -z "$reset_args" ]]; then
            reset_args="--to-earliest"
        fi

        check_prerequisites
        run_kafka_tool "kafka-consumer-groups.sh" "--group" "$group" "--topic" "$topic" "--reset-offsets" $reset_args "--execute"
        ;;
    "consumer-groups-describe-topic")
        if [[ -z "$2" ]] || [[ -z "$3" ]]; then
            echo -e "${RED}Error: Consumer group name and topic required${NC}"
            echo "Usage: $0 consumer-groups-describe-topic <group> <topic>"
            exit 1
        fi
        check_prerequisites
        # Note: --topic cannot be used with --describe in Kafka 4.0
        # We'll get all topics and filter for the specific one
        echo -e "${YELLOW}Note: Getting all topics for group '$2' and filtering for topic '$3'${NC}"
        run_kafka_tool "kafka-consumer-groups.sh" "--describe" "--group" "$2" | grep -E "(GROUP|$3)"
        ;;
    "producer-perf-test")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 producer-perf-test <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-producer-perf-test.sh" "--topic" "$2" "--num-records" "1000" "--record-size" "1000"
        ;;
    "consumer-perf-test")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 consumer-perf-test <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-consumer-perf-test.sh" "--topic" "$2" "--messages" "1000"
        ;;
    "configs-describe")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 configs-describe <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-configs.sh" "--describe" "--topic" "$2"
        ;;
    "configs-alter")
        if [[ -z "$2" ]] || [[ -z "$3" ]]; then
            echo -e "${RED}Error: Topic name and config required${NC}"
            echo "Usage: $0 configs-alter <topic> <key=value>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-configs.sh" "--alter" "--topic" "$2" "--add-config" "$3"
        ;;
    "offsets-get")
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Topic name required${NC}"
            echo "Usage: $0 offsets-get <topic>"
            exit 1
        fi
        check_prerequisites
        run_kafka_tool "kafka-get-offsets.sh" "--topic" "$2"
        ;;
    "features-list")
        check_prerequisites
        run_kafka_tool "kafka-features.sh" "--list"
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
