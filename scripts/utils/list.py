# list.py

import re
import sys
from pathlib import Path

def extract_names_from_file(path):
    """
    Reads a file and extracts all values from the "name" key using regex.
    This approach works even if the JSON is malformed.
    """
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        # Use regex to find all values associated with a "name" key
        names = re.findall(r'"name":\s*"([^"]+)"', content)
        return names
    except FileNotFoundError:
        print(f"Error: File not found at {path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading {path}: {e}", file=sys.stderr)
        sys.exit(1)

def list_and_enumerate(names, title):
    """
    Prints a numbered list of names under a given title.
    """
    print(f"{title}:")
    if not names:
        print("  <none found>")
    else:
        for idx, name in enumerate(names, start=1):
            # The item is now just the name string itself
            print(f"{idx}. {name}")
    print()  # Add a blank line for better readability

def main():
    base = Path(__file__).parent
    agents_path = base / 'agents.json'
    tools_path = base / 'tools.json'

    # Load names directly from the files
    agent_names = extract_names_from_file(agents_path)
    tool_names = extract_names_from_file(tools_path)

    # Sort the simple list of strings (case-insensitively)
    agents_sorted = sorted(agent_names, key=str.lower)
    tools_sorted = sorted(tool_names, key=str.lower)

    # Print the enumerated lists
    list_and_enumerate(agents_sorted, 'Agents')
    list_and_enumerate(tools_sorted, 'Tools')

if __name__ == "__main__":
    main()