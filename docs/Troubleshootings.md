Of course, here is the text converted to Markdown format.

# watsonx Orchestrate Developer Edition Troubleshooting Guide

This document provides solutions to common issues encountered when working with watsonx Orchestrate Developer Edition.

-----

## Docker and Container Management

### Complete System Reset

If you encounter persistent issues with Docker containers or images, use the `purge.sh` script to completely clean your Docker environment:

```bash
# Remove all watsonx Orchestrate Docker images and containers
./purge.sh
```

**What `purge.sh` does:**

  * Stops all running containers
  * Removes all watsonx Orchestrate related containers
  * Removes all watsonx Orchestrate related images
  * Cleans up Docker volumes and networks

### Database Cleanup

If you're experiencing database-related issues or want to reset your local data:

```bash
# Clean the local database
./clean.sh
```

**What `clean.sh` does:**

  * Resets the local database to its initial state
  * Removes all imported agents, tools, and connections
  * Clears conversation history and user data

### Manual Docker Cleanup

If scripts are not available, you can manually clean Docker:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all watsonx orchestrate images
docker rmi $(docker images | grep "ibm-watsonx-orchestrate" | awk '{print $3}')

# Clean up unused volumes and networks
docker system prune -a --volumes
```

-----

## Common Issues and Solutions

### 403 Authorization Error

  * **Problem:** Getting `403 Forbidden` errors when trying to access watsonx Orchestrate services.
  * **Solution:**
      * Ensure you're using the API key from the watsonx Orchestrate settings, not from the IBM Cloud resources page.
      * Verify your API key is still valid (they expire).
      * Check that you're using the correct service instance URL.

### Space Access Issues

  * **Problem:** Cannot access the specified space ID or getting permission errors.
  * **Solution:**
      * Verify that your API key has access to the specified space ID.
      * Check if the space ID is correct and exists.
      * Ensure your IBM Cloud account has the necessary permissions.

### Environment Variables Conflict

  * **Problem:** Environment variables from your system are conflicting with `.env` file settings.
  * **Solution:**
      * If you have `WO_API_KEY` defined in your system environment, unset it:
        ```bash
        unset WO_API_KEY
        ```
      * Check for other conflicting environment variables:
        ```bash
        env | grep WO_
        env | grep WATSONX_
        ```

-----

## Python Environment Issues

### Virtual Environment Not Active

  * **Problem:** Commands not working or packages not found.
  * **Solution:**
      * Always ensure your Python virtual environment is active. Check if it's active:
        ```bash
        echo $VIRTUAL_ENV  # Should show the path to your venv directory
        ```
      * If not active, activate it:
        ```bash
        # For Linux/macOS
        source venv/bin/activate

        # For Windows
        venv\Scripts\activate
        ```

### Command Not Found

  * **Problem:** The `orchestrate` command is not found.
  * **Solution:**
      * Ensure the virtual environment is active and the ADK is installed:
        ```bash
        source venv/bin/activate
        pip install ibm-watsonx-orchestrate
        ```
      * Verify the installation:
        ```bash
        orchestrate --version
        ```

### Package Installation Issues

  * **Problem:** Cannot install or update packages.
  * **Solution:**
      * Upgrade pip first:
        ```bash
        pip install --upgrade pip
        ```
      * Reinstall the ADK:
        ```bash
        pip uninstall ibm-watsonx-orchestrate
        pip install ibm-watsonx-orchestrate
        ```
      * Clear the pip cache if needed:
        ```bash
        pip cache purge
        ```

-----

## Server and Service Issues

### Server Won't Start

  * **Problem:** `orchestrate server start` fails or hangs.
  * **Solution:**
      * Check if Docker is running:
        ```bash
        docker --version
        docker ps
        ```
      * Verify the `.env` file exists and has the correct format:
        ```bash
        cat .env
        ```
      * Check for port conflicts:
        ```bash
        lsof -i :4321  # Check if port 4321 is in use
        lsof -i :3000  # Check if port 3000 is in use
        ```
      * Try starting with verbose logging:
        ```bash
        orchestrate server start --env-file=.env --verbose
        ```

### Server Logs

  * **Problem:** Need to debug server issues.
  * **Solution:**
      * View server logs:
        ```bash
        orchestrate server logs
        ```

### Chat UI Not Loading

  * **Problem:** Chat UI at `http://localhost:3000/chat-lite` is not accessible.
  * **Solution:**
      * Ensure the server is running: `orchestrate server status`
      * Check if the chat service is started: `orchestrate chat start`
      * Verify ports are not blocked by a firewall.

-----

## Environment Management Issues

### Cannot Activate Environment

  * **Problem:** `orchestrate env activate local` fails.
  * **Solution:**
      * Ensure the server is running first.
      * Check available environments: `orchestrate env list`
      * Reset environment configuration:
        ```bash
        rm -rf ~/.config/orchestrate/
        rm -rf ~/.cache/orchestrate/
        ```

### Remote Environment Authentication

  * **Problem:** Cannot authenticate with remote environments.
  * **Solution:**
      * Check API key validity.
      * Re-authenticate:
        ```bash
        orchestrate env activate my-remote-env --api-key your-api-key
        ```
      * Verify the service instance URL is correct.

-----

## Import and Tool Issues

### Agent/Tool Import Failures

  * **Problem:** Cannot import agents or tools.
  * **Solution:**
      * Verify file paths are correct.
      * Check the file format (YAML/JSON syntax).
      * Ensure the environment is activated: `orchestrate env activate local`
      * Check for dependency issues in Python tools:
        ```bash
        orchestrate tools import -k python -f tool.py -r requirements.txt
        ```

-----

## Models and Function Calling

### Models Compatible with Function Calling

Based on the watsonx Orchestrate ADK documentation, the following models support function calling (tools):

  * **IBM Granite Models (Recommended)**
      * `watsonx/ibm/granite-3-8b-instruct`
      * `watsonx/ibm/granite-3-2b-instruct`
  * **Meta Llama Models**
      * `watsonx/meta-llama/llama-3-3-70b-instruct`
      * `watsonx/meta-llama/llama-3-1-70b-instruct`
      * `watsonx/meta-llama/llama-3-1-8b-instruct`
      * `watsonx/meta-llama/llama-3-2-90b-vision-instruct`
  * **Other Compatible Models**
      * `watsonx/mistralai/mixtral-8x7b-instruct-v01`
      * `watsonx/mistralai/mistral-large`

### Model Not Supporting Tools

  * **Problem:** The agent is not calling tools properly.
  * **Solution:**
      * Verify you're using a function-calling compatible model from the list above.
      * Check agent configuration to ensure a compatible model is specified, for example: `llm: watsonx/ibm/granite-3-8b-instruct`.

-----

## Network and Connectivity Issues

### Cannot Pull Docker Images

  * **Problem:** Docker images fail to download.
  * **Solution:**
      * Check internet connectivity.
      * Verify credentials in the `.env` file.
      * Try skipping login if images already exist by setting this in your `.env` file: `WO_DEVELOPER_EDITION_SKIP_LOGIN=true`

### Proxy Issues

  * **Problem:** A corporate firewall/proxy is blocking connections.
  * **Solution:**
      * Configure Docker proxy settings.
      * Set environment variables:
        ```bash
        export HTTP_PROXY=http://proxy.company.com:8080
        export HTTPS_PROXY=http://proxy.company.com:8080
        ```

-----

## Best Practices Summary

  * **Python Virtual Environment:** Always use `source venv/bin/activate` to isolate Python packages.
  * **watsonx Orchestrate Environment:** Use `orchestrate env activate <name>` to target deployment environments.
  * **Always activate both:** First, activate your Python virtual environment, then your watsonx Orchestrate environment.
  * **Local vs Remote:** Use `local` for development and create named environments for production deployments.
  * **Automatic Scripts:** Once you have created the Python environment and `.env` file, you can reference the `start.sh` and `run.sh` scripts for automated setup and agent importing.

-----

## Getting Help

If issues persist:

  * Check the official documentation.
  * Verify all prerequisites are met.
  * Try the complete reset procedure (`purge.sh` + `clean.sh`).
  * Check GitHub issues for similar problems.
  * Contact IBM support with detailed error logs.

-----

## Emergency Reset Procedure

If everything fails, perform a complete reset:

```bash
# 1. Stop all services
orchestrate server stop

# 2. Clean Docker environment
./purge.sh

# 3. Clean database
./clean.sh

# 4. Remove configuration
rm -rf ~/.config/orchestrate/
rm -rf ~/.cache/orchestrate/

# 5. Recreate virtual environment
deactivate
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install ibm-watsonx-orchestrate

# 6. Restart from the beginning
orchestrate server start --env-file=.env
```