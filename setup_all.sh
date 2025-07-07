#!/bin/bash
# setup.sh - Complete setup: start server, import agents, start UI

echo "=== Complete watsonx Orchestrate Setup ==="

# Start server in background
echo "Starting server..."
./start.sh &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to initialize..."
sleep 30

# Run the import process
echo "Running agent import..."
./run.sh

# Clean up
echo "Setup complete!"