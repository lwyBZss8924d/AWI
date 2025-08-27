#!/bin/bash
# Carbonyl test suite - Test with common websites
# Usage: ./dev-test.sh

set -e

echo "🧪 Testing Carbonyl with common websites..."
echo ""

test_sites=(
    "https://example.com"
    "https://github.com"
    "https://news.ycombinator.com"
    "https://en.wikipedia.org"
)

for site in "${test_sites[@]}"; do
    echo "Testing: $site"
    echo "Press Ctrl+C to continue to next site, or 'q' to quit Carbonyl"
    ./dev-run.sh "$site" || true
    echo "---"
done

echo "✅ Test suite complete!"