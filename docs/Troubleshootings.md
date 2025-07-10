## Troubleshooting Common Issues
### 403 Authorization Error:

Ensure you're using the API key from watsonx Orchestrate settings, not from IBM Cloud resources page
Space Access Issues:

Verify that your API key has access to the specified space ID
Environment Variables Conflict:
If you have WO_API_KEY defined in your system environment:
```
unset WO_API_KEY
```
## Python Environment Issues:
Always ensure your Python virtual environment is active:

### Check if virtual environment is active
```
echo $VIRTUAL_ENV  # Should show path to your venv directory
```
### If not active, activate it

```
source venv/bin/activate
```
Command Not Found:
If orchestrate command is not found:

### Ensure virtual environment is active and ADK is installed
```
source venv/bin/activate
pip install ibm-watsonx-orchestrate
```
Python Virtual Environment: Use source venv/bin/activate to isolate Python packages
watsonx Orchestrate Environment: Use orchestrate env activate <name> to target deployment environments
Always activate both: First activate your Python virtual environment, then your watsonx Orchestrate environment
Local vs Remote: Use local for development, create named environments for production deployments
Automatic Scripts: Once you have created the Python environment and .env file, you can reference start.sh and run.sh scripts for automated setup and agent importing
The key difference from the original tutorial is that all commands are now provided inline instead of being hidden in scripts, making the process more transparent and easier to understand and customize.


Models Compatible with Function Calling
Based on the watsonx Orchestrate ADK documentation, here are the models that support function calling (tools):

IBM Granite Models (Recommended)
watsonx/ibm/granite-3-8b-instruct
watsonx/ibm/granite-3-2b-instruct
watsonx/ibm/granite-3-8b-instruct (latest version)
Meta Llama Models
watsonx/meta-llama/llama-3-3-70b-instruct
watsonx/meta-llama/llama-3-1-70b-instruct
watsonx/meta-llama/llama-3-1-8b-instruct
watsonx/meta-llama/llama-3-2-90b-vision-instruct
Other Compatible Models
watsonx/mistralai/mixtral-8x7b-instruct-v01
watsonx/mistralai/mistral-large

