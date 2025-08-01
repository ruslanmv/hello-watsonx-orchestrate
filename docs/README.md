## 🚀 **From Zero to Hero: Building a Multi-Agent System with Watsonx Orchestrate**

### **Introduction**

Welcome to the world of AI agents\! In this tutorial, you'll learn how to build a **multi-agent system**. Instead of a single, monolithic AI, we will create a team of specialized agents that collaborate to solve problems. Our system will have:

  * **Greeting Agent**: A specialist for handling greetings.
  * **Echo Agent**: A simple agent that repeats any general message.
  * **Calculator Agent**: A powerful agent that can perform math using a Python tool.
  * **Orchestrator Agent**: The "manager" agent that receives all user requests and decides which specialist should handle the task.

This "manager-worker" pattern is fundamental to creating sophisticated and reliable AI systems. Let's get started\!


## Environment Configuration for watsonx Orchestrate Developer Edition

There are different ways to configure the **Watsonx Orchestrate Developer Edition** depending on your account type and requirements. This guide will walk you through the correct procedures for each configuration option.

### **Prerequisites**

Before you begin, make sure you have the following:

1.  **Python 3.11+**: Ensure Python and `pip` are installed and accessible from your command line.
2.  **Docker**: The ADK development server runs in a Docker container, so you must have Docker Desktop or another container environment (like Colima) installed and running.
3.  **IBM Cloud Account** 

-----

### **Step 1: Project Setup**

To make things easier, all the code for this tutorial is ready for you. Let's clone the repository and set up a clean Python environment.

## **Clone the Project Files**
    Open your terminal and run the following command to download all the necessary YAML and Python files.

```bash
git clone https://github.com/ruslanmv/hello-watsonx-orchestrate.git

```
we change the directory to
```bash
cd hello-watsonx-orchestrate
```
## Create virtual environment

Before configuring watsonx Orchestrate, ensure you have:
Python Virtual Environment Setup.
First, create and activate a Python virtual environment:

```bash
python -m venv venv
```
### Activate the virtual environment

On Linux/macOS:
```bash
source venv/bin/activate  
```
On Windows:
```bash
venv\Scripts\activate     
```
## Watsonx Orchestrate ADK Installation

Now, we'll install the IBM watsonx Orchestrate Agent Developer Kit (ADK) and start the local development server.

**Install the ADK**
    Use `pip` to install the core `orchestrate` library.

    ```bash
    pip install --upgrade ibm-watsonx-orchestrate==1.6.2
    ```

### File Configuration Options

There are different ways to login [watson orchestratehere](https://www.ibm.com/docs/en/watsonx/watson-orchestrate/base?topic=orchestrate-logging-in-watsonx). In particular we are going to login via cli via Orchestrate Developer Edition.

The watsonx Orchestrate Developer Edition can be configured using three main approaches. Choose the one that matches your setup:

## Option 1: Using watsonx.ai Account (Recommended for Local Development)

This option requires a watsonx.ai instance and an entitlement key from My IBM.

### Create .env file with watsonx.ai configuration
```bash
cat > .env << EOF
WO_DEVELOPER_EDITION_SOURCE=myibm
WO_ENTITLEMENT_KEY=<your_entitlement_key_from_myibm>
WATSONX_APIKEY=<your_watsonx_api_key>
WATSONX_SPACE_ID=<your_space_id>
WO_DEVELOPER_EDITION_SKIP_LOGIN=false
EOF
```
### Requirements:

- Valid watsonx.ai instance on IBM Cloud
- Entitlement key from My IBM
- watsonx.ai API key and Space ID

## Option 2: Using watsonx Orchestrate Account (Version 1.5.0+)
This is the preferred method if you have a watsonx Orchestrate account.

### Create .env file with watsonx Orchestrate configuration

```bash
cat > .env << EOF
WO_DEVELOPER_EDITION_SOURCE=orchestrate
WO_INSTANCE=<your_service_instance_url>
WO_API_KEY=<your_wxo_api_key>
EOF
```
### Requirements:

- Active watsonx Orchestrate account
- Service instance URL from your watsonx Orchestrate settings
- API key generated from watsonx Orchestrate settings

## Option 3: Hybrid Approach (Fallback Method)
Use this if Option 2 doesn't work for pulling images.

### Create .env file with hybrid configuration
```bash
cat > .env << EOF
WO_DEVELOPER_EDITION_SOURCE=myibm
WO_ENTITLEMENT_KEY=<your_entitlement_key>
WO_INSTANCE=<your_service_instance_url>
WO_API_KEY=<your_wxo_api_key>
WO_DEVELOPER_EDITION_SKIP_LOGIN=false
EOF
```

## Getting Credentials for IBM Cloud watsonx Orchestrate (Option 2)

Important: Don't use the credentials from the IBM Cloud resources page directly. Follow this specific procedure to get the correct credentials for Option 2 configuration:

### Step 1: Access Your watsonx Orchestrate Instance

Log in to your  [IBM Cloud Account](https://cloud.ibm.com/)

Log in with your IBM Cloud credentials

If you don't have an account, create an [IBM Cloud account](https://cloud.ibm.com/registration). Complete the registration form, and click Create account.
Go to your [Resources list](https://cloud.ibm.com/resources)

Navigate to the [watsonx Orchestrate catalog](https://cloud.ibm.com/catalog/services/watsonx-orchestrate?) page on IBM Cloud.


On the plan catalog page, select Trial plan and choose your data center location from the Select a location drop-down.

![](assets/2025-07-05-23-59-53.png)

The Service name is pre-filled, you can modify it if needed.
The resource group is set to Default.

Accept the license agreement and click Create to provision a watsonx Orchestrate instance on IBM Cloud. The services page is displayed.

Click Launch watsonx Orchestrate to access the service page and start using the service.

![](assets/2025-07-06-00-00-40.png)

Navigate to Resource list
Find your watsonx Orchestrate product under the AI/Machine Learning resource category

![](assets/2025-07-09-12-50-28.png)


Click on your watsonx Orchestrate instance

![](assets/2025-07-09-13-41-25.png)

Click Launch watsonx Orchestrate

![](assets/2025-07-09-10-31-47.png)

## Step 2: Access API Settings
Once you're logged into your watsonx Orchestrate instance:

Click your user icon on the top right Click Settings

![](assets/2025-07-09-13-45-35.png)

Go to the API details tab

## Step 3: Get Service Instance URL (WO_INSTANCE)

Copy the service instance URL from the API details tab. This will be in the format:

https://api.<region>.watson-orchestrate.ibm.com/instances/<wxo_instance_id>

Save this value for the WO_INSTANCE variable in your .env file.

![](assets/2025-07-09-13-47-44.png)

## Step 4: Generate API Key (WO_API_KEY)

Click the Generate API key button

This redirects you to the IBM Cloud Identity Access Management center

Important: Verify that you are in the correct Account where you have access to watsonx Orchestrate

![](assets/2025-07-09-13-50-52.png)

Click Create to create a new API Key

Enter a name and description for your API Key

![](assets/2025-07-09-13-55-36.png)

Copy the API key and store it securely - this will be your WO_API_KEY value

## Step 5: Set WO_DEVELOPER_EDITION_SOURCE

For Option 2, set WO_DEVELOPER_EDITION_SOURCE=orchestrate

Important Notes:

API keys are not retrievable and can't be edited or deleted
Store your API key in a safe location immediately after generation
You're limited to 10 API keys in this environment

## Getting Credentials for IBM Cloud using watsonx.ai Account (Option 1)

Follow these steps to obtain all the required credentials for Option 1 configuration:

### Step 1: Get Entitlement Key from My IBM (WO_ENTITLEMENT_KEY)

Access [My IBM](https://myibm.ibm.com/)

Click View Library

![](assets/2025-07-04-22-20-41.png)

Click Add a new key +

![](assets/2025-07-04-22-21-51.png)

Copy the entitlement key - this will be your 

WO_ENTITLEMENT_KEY value

![](assets/2025-07-04-22-22-26.png)

## Step 2: Create watsonx.ai Instance and Get Space ID (WATSONX_SPACE_ID)
Create a watsonx.ai instance on IBM Cloud (if you don't have one already)


Go to your [watsonx instance](https://dataplatform.cloud.ibm.com/wx/home?context=wx)

![](assets/2025-07-09-18-21-35.png)

Scrow down and click [Create a new deployment space](https://
dataplatform.cloud.ibm.com/ml-runtime/spaces/create-space?context=wx)

![](assets/2025-07-09-18-22-05.png)

here we give an orignal name for example 

`watsonx-ochestrate-1` 

for exmaple,

![](assets/2025-07-09-18-24-37.png)

for this demo we will use Deployment stage `Development`

and we choose watsonx.ai Runtime appropiate.

and we create it.
![](assets/2025-07-09-18-27-13.png)

Go to the Developer access page on IBM Cloud

Go to this page

[Developer access ](https://dataplatform.cloud.ibm.com/developer-access?context=wx)

![](assets/2025-07-05-23-41-03.png)

Locate your space ID - this will be your WATSONX_SPACE_ID value
You can also create a new space if needed from this page


## Step 3: Get watsonx.ai API Key (WATSONX_APIKEY)

In your IBM Cloud account, go to Manage → Access (IAM)

Click on API keys in the left sidebar

Click Create an IBM Cloud API key


[https://cloud.ibm.com/iam/apikeys](https://cloud.ibm.com/iam/apikeys)

![](assets/2025-07-09-18-30-08.png)

Enter a name and description for your API key

Click Create

Copy the API key immediately - this will be your 

WATSONX_APIKEY value

Store it securely as it cannot be retrieved later

Alternative method for API key:

Go to Managing API Keys

Follow the IBM Cloud documentation to create your API key

## Step 4: Set Additional Variables

We add to additional variables

```bash
WO_DEVELOPER_EDITION_SOURCE=myibm
```

```bash
WO_DEVELOPER_EDITION_SKIP_LOGIN=false 
```

(you can set this to true to skip ICR login if you already have the images)

So complete Option 1 .env file example:

```bash
cat > .env << EOF
WO_DEVELOPER_EDITION_SOURCE=myibm
WO_ENTITLEMENT_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...
WATSONX_APIKEY=your-ibm-cloud-api-key-here
WATSONX_SPACE_ID=12345678-1234-1234-1234-123456789abc
WO_DEVELOPER_EDITION_SKIP_LOGIN=false
EOF
```

Important Notes for Option 1:

The entitlement key is a JWT token that will be quite long
The Space ID is a UUID format identifier
The API key is your IBM Cloud API key, not a watsonx Orchestrate specific key

Make sure your IBM Cloud API key has access to the watsonx.ai service and the specified space
Starting the Developer Edition
Once your .env file is configured and your Python virtual environment is active:

### Ensure Python virtual environment is active
```bash
source venv/bin/activate
```

### Start the watsonx Orchestrate Developer Edition
```bash
orchestrate server start --env-file=.env
```

![](assets/2025-07-10-07-53-50.png)

## Environment Management


### Activate local environment
After starting the server, activate the local environment:
```bash
orchestrate env activate local
```
![](assets/2025-07-10-07-54-58.png)
### Environment Management Commands
List Available Environments:

```bash
orchestrate env list
```

Example output:

```bash
local                      http://localhost:4321                                                 (active)
```

Just like information if we want ran the remote environment from the cloud you can choose one of the follwoing options

## Add Remote Environment (optional):
### For IBM Cloud
For the case of IBM cloud  you can type

```bash
orchestrate env add -n my-ibm-cloud-env -u https://your-service-instance-url --type ibm_iam --activate
```
and if you want to see 

```bash
orchestrate env list
```
Example output:

```bash
my-ibm-cloud-env          https://api.watson-orchestrate.cloud.ibm.com/instances/<instance-id>
```

### For AWS

And similar for aws

```bash
orchestrate env add -n my-aws-env -u https://your-service-instance-url --type mcsp --activate

```bash
orchestrate env list
```

Example output:

```bash
my-aws-env                https://api.watson-orchestrate.ibm.com/instances/<instance-id>
```

### Switch Between Environments:

### Switch to local development environment

```bash
orchestrate env activate local
```

### Switch to remote production environment

```bash
orchestrate env activate my-ibm-cloud-env
```
## Authentication for Remote Environments:

Authenticate against remote environment (expires every 2 hours)

```bash
orchestrate env activate my-ibm-cloud-env --api-key your-api-key
```

Or authenticate interactively

```bash
orchestrate env activate my-ibm-cloud-env
```
You'll be prompted: Please enter WXO API key:

## Working with Agents and Tools
Once your environment is set up and activated, you can work with agents and tools:

### Import tools
```bash
orchestrate tools import -k python -f tools/calculator_tool.py
```
### Import agents

```bash
orchestrate agents import -f agents/greeter.yaml
```

### List imported agents and tools

```bash
orchestrate agents list
orchestrate tools list
```

### Start the chat UI

```bash
orchestrate chat start
```

The chat UI will be available at: http://localhost:3000/chat-lite

Complete Workflow Example
Here's a complete workflow from setup to running:

```bash
# 1. Activate Python virtual environment
source venv/bin/activate

# 2. Verify ADK installation
orchestrate --version

# 3. Create .env file with your credentials (choose one option from above)
cat > .env << EOF
WO_DEVELOPER_EDITION_SOURCE=orchestrate
WO_INSTANCE=https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/your-instance-id
WO_API_KEY=your-api-key
EOF

# 4. Start Developer Edition
orchestrate server start --env-file=.env

# 5. In another terminal, activate Python environment and local watsonx environment
source venv/bin/activate
orchestrate env activate local

# 6. Now you can work with agents and tools
orchestrate agents list
orchestrate tools list

# 7. Start chat UI
orchestrate chat start
```



### Create and Validate Your Agents

The project you cloned contains all the agent definitions. Let's review them and learn how to validate them before use.

A best practice is to run `orchestrate validate -f <your-file.yaml>` before importing anything. This command checks for typos, incorrect model IDs, and other common errors.

#### **Agent 1: The Greeting Agent (`greeting_agent.yaml`)**

This agent's only job is to respond to greetings. Note the instructions are written to be case-insensitive.

```yaml
spec_version: v1
kind: native
name: greeting_agent
description: A friendly agent that handles greetings only.
style: react
llm: watsonx/meta-llama/llama-3-2-90b-vision-instruct
instructions: |
  You are the Greeting Agent.
  • If the user's message contains the word **“hello”** (case-insensitive),
    respond with exactly:  
      **Hello! I am the Greeting Agent.**
  • For every other input, say:  
      **I only handle greetings. Please say "hello".**
tools: []


```

*Validate it:* `orchestrate validate -f greeting_agent.yaml`

#### **Agent 2: The Echo Agent (`echo_agent.yaml`)**

This agent echoes any input back, using the correct `{input}` placeholder for the user's message.

```yaml
# echo_agent.yaml
spec_version: v1
kind: native
name: echo_agent
description: An agent that echoes the user’s input back verbatim.
style: react
llm: watsonx/meta-llama/llama-3-2-90b-vision-instruct
instructions: |
  You are the Echo Agent.
  Always repeat the user's exact input.
  Format your reply as:  
    **The Echo Agent heard you say: {input}**
tools: []

```

*Validate it:* `orchestrate validate -f echo_agent.yaml`


#### **The Collaborator Pattern**

The Orchestrator Agent will manage our other agents. It uses the `collaborators` keyword to gain access to them. The message flow looks like this:

```ascii
     User Input
          │
          ▼
┌────────────────────┐
│ Orchestrator Agent │
└────────────────────┘
          │
          ├─► If "hello" is in message... ─► ┌────────────────┐
          │                                  │ Greeting Agent │
          │                                  └────────────────┘
          │
          ├─► If message is math... ───────► ┌──────────────────┐
          │                                  │ Calculator Agent │
          │                                  └──────────────────┘
          │
          └─► Otherwise... ────────────────► ┌──────────────┐
                                             │  Echo Agent  │
                                             └──────────────┘
```

#### **Agent 3: The Orchestrator Agent (`orchestrator_agent.yaml`)**

This is the brain of our system. It contains the routing logic to delegate tasks to the correct specialist.

```yaml
# orchestrator_agent.yaml
spec_version: v1
kind: native
name: orchestrator_agent
description: Routes user requests to the appropriate specialist agent.
style: react
llm: watsonx/meta-llama/llama-3-2-90b-vision-instruct
collaborators:
  - greeting_agent
  - calculator_agent
  - echo_agent
instructions: |
  You are the Orchestrator Agent. Delegate as follows:

  1. If the user's message contains the word "hello" (case-insensitive),
     delegate to **greeting_agent**.

  2. Else if the message appears to ask for mathematical operations like:
     - Addition: "add", "plus", "sum", "+", "5 + 3"
     - Subtraction: "subtract", "minus", "-", "10 - 5"  
     - Multiplication: "multiply", "times", "*", "4 * 6"
     - Division: "divide", "/", "20 / 4"
     delegate to **calculator_agent**.

  3. Otherwise, delegate to **echo_agent**.

  Do not answer directly yourself. Always delegate to the appropriate collaborator and return their exact response.
tools: []
```

*Validate it:* `orchestrate validate -f orchestrator_agent.yaml` (This will fail for now, as it doesn't know about `calculator_agent` yet. We'll fix that next\!)

-----

### **The "Hero" Leap - Empowering Agents with Python Tools**

Agents that only talk are useful, but agents that *do things* are powerful. Here’s how we create our `calculator_agent`. **Order is critical**: we must create and import the tool *before* the agent that uses it.

#### **4.1: Create the Python Tool (`calculator_tool.py`)**

The ADK requires the `@tool` decorator to discover and register a Python function.

```python
# calculator_tool.py
from ibm_watsonx_orchestrate.agent_builder.tools import tool

@tool
def add(a: float, b: float) -> float:
    """
    Add two numbers together.
    
    :param a: The first number to add
    :param b: The second number to add
    :returns: The sum of a and b
    """
    return a + b

@tool
def subtract(a: float, b: float) -> float:
    """
    Subtract the second number from the first number.
    
    :param a: The number to subtract from
    :param b: The number to subtract
    :returns: The difference of a and b
    """
    return a - b

@tool
def multiply(a: float, b: float) -> float:
    """
    Multiply two numbers together.
    
    :param a: The first number to multiply
    :param b: The second number to multiply
    :returns: The product of a and b
    """
    return a * b

@tool
def divide(a: float, b: float) -> float:
    """
    Divide the first number by the second number.
    
    :param a: The dividend (number to be divided)
    :param b: The divisor (number to divide by)
    :returns: The quotient of a divided by b
    """
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b
```

#### **Create the Calculator Agent (`calculator_agent.yaml`)**

This agent is explicitly designed to use our new `add` tool.

```yaml
spec_version: v1
kind: native
name: calculator_agent
description: Performs mathematical calculations including addition, subtraction, multiplication, and division.
style: react
llm: watsonx/meta-llama/llama-3-2-90b-vision-instruct
instructions: |
  You are a calculator agent that can perform basic mathematical operations.
  
  • When asked to add or sum numbers, call the `add` tool
  • When asked to subtract numbers, call the `subtract` tool  
  • When asked to multiply numbers, call the `multiply` tool
  • When asked to divide numbers, call the `divide` tool
  
  Always use the appropriate tool for the mathematical operation requested.
  Do NOT compute results yourself - always use the tools.
  After the tool returns a result, present it clearly to the user.
  
  Handle these types of requests:
  - "add 5 and 3" or "5 + 3" → use add tool
  - "subtract 10 from 15" or "15 - 10" → use subtract tool
  - "multiply 4 by 6" or "4 * 6" → use multiply tool
  - "divide 20 by 4" or "20 / 4" → use divide tool
tools:
  - add
  - subtract
  - multiply
  - divide
```

*Validate it:* `orchestrate validate -f calculator_agent.yaml`

-----

### **Import and Test Your Multi-Agent System**

With all our files defined and validated, let's import them into Orchestrate and start chatting.

1.  **Open a NEW terminal window** (leave the server running) and activate your virtual environment.

2.  **Import the Tool First**
    Tools must exist before the agents that rely on them.

    ```bash
    orchestrate tools import -k python -f tools/calculator_tool.py
    ```

3.  **Import the Agents**
    Now import all the agents.

```bash
orchestrate agents import -f agents/greeting_agent.yaml
orchestrate agents import -f agents/calculator_agent.yaml  
orchestrate agents import -f agents/echo_agent.yaml
  ```
```bash    
# Finally import the orchestrator
orchestrate agents import -f agents/orchestrator_agent.yaml
```

4.  **Start the Chat\!**

    This command launches the chat UI. We point it to our `orchestrator_agent`, which will be the entry point. Note the plural `--agents` flag.

```bash
orchestrate chat start --agents orchestrator_agent
```


4. Check Agent Status
Verify your agents were imported correctly:
```bash
orchestrate agents list
```
5. Try Different Agent Styles
If the issue persists, try changing the style from react to default in your agent configurations, as mentioned in the known issues documentation.

6. Test Individual Agents First
Before testing the orchestrator, try testing individual agents directly to ensure they work:

Test with "hello" to see if greeting_agent responds
Test with "add 2 and 3" to see if calculator_agent responds
The most likely cause is the first interaction failure issue. Try waiting a few minutes after startup and then retry your messages. If that doesn't work, check your agent configurations and import order as described above.


## How to Test Individual Agents
1. Using the Chat Interface with Agent Selection
When you start the chat interface, you can select specific agents to test:

Start the chat interface:

orchestrate chat start

Access the chat UI:
Navigate to http://localhost:3000/chat-lite in your browser

Select a specific agent:
In the chat interface, you'll see a list of available agents. You can select the specific agent you want to test from this list.

2. Testing Individual Agents via CLI Commands
You can also test agents individually using CLI commands:

# List all available agents
orchestrate agents list

# Test a specific agent directly (if supported)
# This would show you which agents are available for testing

3. Testing Each of Your Agents
For your specific project, test each agent individually:

Test the Greeting Agent:

Select greeting_agent in the chat interface
Type: "hello"
Expected response: "Hello! I am the Greeting Agent."

![](assets/2025-07-07-22-31-10.png)


Test the Calculator Agent:

Select calculator_agent in the chat interface
Type: "add 5 and 3"
Expected response: The agent should call the add tool and return the result
![](assets/2025-07-07-22-32-28.png)

Test the Echo Agent:

Select echo_agent in the chat interface
Type: "test message"
Expected response: "The Echo Agent heard you say: test message"

![](assets/2025-07-07-22-33-04.png)

Test the Orchestrator Agent:

Select orchestrator_agent in the chat interface
Try different inputs to test routing:
"hello" → should route to greeting_agent
"add 2 and 2" → should route to calculator_agent
![](assets/2025-07-07-22-35-46.png)
You can analize the reasoning
![](assets/2025-07-07-22-36-34.png)



"anything else" → should route to echo_agent
Available LLM Models
Your LLM Configuration is Correct
Yes, llm: watsonx/meta-llama/llama-3-8b-instruct is a correct and valid LLM specification.




## Choosing the Right "Brain": A World of LLM Possibilities

We've successfully tested our agents, and they work beautifully. But what gives them their spark? The answer is the **Large Language Model (LLM)**, the "brain" behind each agent's reasoning. One of the greatest strengths of the watsonx Orchestrate ADK is its flexibility. You are not locked into a single provider; you are given the keys to a whole universe of AI models.

At the core, you have seamless integration with **watsonx.ai**, giving you access to powerful, enterprise-ready models like the **Llama 3 series** and IBM's own high-performance **Granite** models. The `llm: watsonx/meta-llama/llama-3-8b-instruct` we used is just one of many excellent choices.


You can see the full roster of available models in your own environment at any time. Just open your terminal and run:

```bash
# See all available models
orchestrate models list
```

This command empowers you to choose the perfect intelligence for any task, ensuring your agents are not just functional, but truly smart.

-----

## The Final Performance: Putting Your Multi-Agent System to the Test

It's time for the moment of truth. With our agents built and our server running, let's open the chat interface at `http://localhost:3000/chat-lite` and witness our creation in action.

First, a simple greeting. Type in **`hello there`**.
Instantly, you'll see the Orchestrator Agent spring to life. It recognizes the intent, and instead of answering itself, it passes the baton to the specialist. The `greeting_agent` takes over and delivers its perfectly crafted line: `Hello! I am the Greeting Agent.`

Now for something more challenging. Let's test its tool-using capability with **`what is 11 plus 54?`**.
Watch closely. The Orchestrator understands this isn't a greeting; it's a request for calculation. It awakens the `calculator_agent`, which in turn knows it needs to call the `add` function from our Python tool. The tool does the heavy lifting, and the agent presents the final, correct answer.

Finally, let's give it a query that fits no specific category, like **`This is a test`**.
The Orchestrator, seeing no match for greetings or math, wisely defaults to its fallback plan. It delegates the task to the `echo_agent`, which dutifully reports back: `The Echo Agent heard you say: This is a test.`

**Congratulations\!** You have successfully built, orchestrated, and validated a smart, tool-enabled, multi-agent system. 🎉

-----

### 🧹 The Responsible Hero: Cleaning Up Your Workspace

A true professional knows that cleaning up is just as important as building. When you're finished experimenting, it's good practice to remove the assets you've created to keep your environment tidy.

You can do this with a few simple commands. From a terminal with your virtual environment active, run the following to dismantle your system piece by piece:

```bash
# It's best practice to delete agents first
orchestrate agents delete orchestrator_agent
orchestrate agents delete calculator_agent
orchestrate agents delete greeting_agent
orchestrate agents delete echo_agent

# Then, delete the tool the agents relied on
orchestrate tools delete add

# Finally, in the terminal where the server is running,
# press Ctrl+C and then run the stop command:
orchestrate server stop
```

-----

### 🤔 When Heroes Stumble: A Troubleshooting Guide

Even the best developers run into a few snags. If your system isn't behaving as expected, don't worry. Here are solutions to some common challenges:

  * **Getting an `Agent not found` error?**
    This usually means there's a typo in your `orchestrator_agent.yaml`'s `collaborators` list, or you forgot to import one of the agents. Double-check your spelling and run `orchestrate agents list` to ensure everyone is present.

  * **Seeing a `Tool for agent not found` error?**
    This is almost always an import order issue. Remember the golden rule: **tools must be imported *before* the agents that use them.** Delete the agent, re-import your tool, and then import the agent again.

  * **The server fails with `Address already in use`?**
    This classic error simply means another process (likely a previous server instance) is already using a required port. Stop the old server with `orchestrate server stop` before starting a new one.

-----

### 🎓 Your Journey is Just Beginning

From a simple idea to a collaborating team of specialized AI agents, you've gone from zero to hero. You've learned the fundamentals of building with watsonx Orchestrate, but your adventure is far from over. You now have a powerful foundation to build upon. Here are the new quests you can embark on:

  * **Grant Your Agents Vast Knowledge:** Move beyond simple instructions. With **Knowledge Bases**, you can feed your agents PDFs, documents, and web content, allowing them to answer complex questions based on a rich set of information.

  * **Master Complex Tasks with the Flow Builder:** For workflows that require multiple, sequential steps, the **Flow Builder** is your visual spellbook. Chain tools and logic together to create sophisticated automations without writing extensive code.

  * **Forge an Unbreakable System with Unit Tests:** For production-grade reliability, the ADK includes a Python SDK that lets you write **unit tests** for your agents' behavior. This is perfect for integrating your agent development into a professional CI/CD pipeline.

### **Conclusion**

Today, you didn't just build a simple AI; you learned how to **orchestrate intelligence**. You created a system where different agents, each with a unique skill, collaborate under the direction of a manager to solve problems more effectively than a single agent ever could. This "manager-worker" pattern is a cornerstone of creating scalable, reliable, and powerful AI solutions.

The power is now in your hands. Take these concepts, explore the advanced features, and start building automations that solve real-world problems. We can't wait to see what you create.