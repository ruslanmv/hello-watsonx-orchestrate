# 🖐️ Hello watsonx Agents

A minimal, fully-working **multi-agent demo** for the  
[IBM watsonx-Orchestrate ADK](https://ibm.biz/wxo-adk-docs).

> **Agents included**
> 1. `greeting_agent` – answers any greeting  
> 2. `echo_agent` – repeats whatever the user says  
> 3. `calculator_agent` – performs addition by calling a Python tool  
> 4. `orchestrator_agent` – routes every request to the right specialist  
> 5. `add` tool – a registered Python function used by `calculator_agent`

---

## ✨ Quick start (5 commands)

```bash
git clone https://github.com/ruslanmv/hello-watsonx-agents.git
cd hello-watsonx-agents

bash setup.sh                 # venv → pip install → start server → import all
orchestrate chat start --agents orchestrator_agent
````

Open the URL printed in the terminal and try:

| User input            | Expected answer (agent path)                           |
| --------------------- | ------------------------------------------------------ |
| `hello there`         | **Hello! I am the Greeting Agent.** (greeter)          |
| `what is 11 plus 54`  | **The result of 11 + 54 is 65.** (calculator ➜ tool)   |
| `this is only a test` | **The Echo Agent heard you say: this is only a test.** |

---

## 📂 Project layout

```
.
├── agents/              # YAML definitions
│   ├── greeting_agent.yaml
│   ├── echo_agent.yaml
│   ├── calculator_agent.yaml
│   └── orchestrator_agent.yaml
├── tools/
│   └── calculator_tool.py
├── tests/               # pytest sample
│   └── test_router.py
├── setup.sh             # one-shot bootstrap script
├── requirements.txt
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🧪 Running tests locally

```bash
source venv/bin/activate             # if not already
pytest -q
```

CI (GitHub Actions) automatically validates the YAML and runs the same tests on every push / PR.

---

## 🛠 Troubleshooting

| Symptom                        | Fix                                                                                                              |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `tool 'add' not found`         | Run `orchestrate tools list` – if empty, re-run `setup.sh` (tools must be imported **before** agents).           |
| `Address already in use :8080` | Another Orchestrate server is running. `orchestrate server stop` first, or kill the container in Docker Desktop. |
| Chat page 404                  | Ensure `orchestrate server start --accept-license` is still running in a terminal tab.                           |

---

## 🤝 Contributing

Pull requests and issues welcome! Please run `pytest` and ensure CI passes before submitting.

---

## 📝 License

This repository is released under the MIT License (see `LICENSE`).



How to Use:
Run the script as usual
When prompted, choose "Y" to install the demo agent
The script will create and import the demo agent automatically
Start the chat interface and test with phrases like:
"Hello" or "Give me a greeting"
"What time is it?" or "Show me the current time"
This demo agent provides a simple way to test that watsonx Orchestrate is working correctly without requiring complex external integrations or APIs.

start-watsonx-orchestrate-demo.sh