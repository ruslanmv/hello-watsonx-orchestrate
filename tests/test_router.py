"""
Very lightweight checks that verify our YAML wiring
without needing to spin up the Orchestrate server.

If these tests pass in CI, we know:

1.  All agent YAML files parse correctly.
2.  The orchestrator lists the expected collaborators.
3.  The routing rules mention every collaborator by name.
"""

from pathlib import Path
import yaml


AGENT_PATH = Path("agents")
ORCH_FILE = AGENT_PATH / "orchestrator_agent.yaml"


def test_yaml_loads():
    """All agent YAML files should be valid and parseable."""
    for path in AGENT_PATH.glob("*.yaml"):
        with path.open(encoding="utf-8") as fp:
            yaml.safe_load(fp)  # will raise on syntax error


def test_orchestrator_collaborators():
    """The orchestrator must reference all three worker agents."""
    data = yaml.safe_load(ORCH_FILE.read_text(encoding="utf-8"))
    assert set(data["collaborators"]) == {
        "greeting_agent",
        "calculator_agent",
        "echo_agent",
    }


def test_orchestrator_instructions_contain_delegation_clauses():
    """The routing instructions should mention each collaborator."""
    data = yaml.safe_load(ORCH_FILE.read_text(encoding="utf-8"))
    instructions = data["instructions"]
    for name in ("greeting_agent", "calculator_agent", "echo_agent"):
        assert name in instructions, f"Missing delegate rule for {name}"
