# clean.py

import re
import sys
import subprocess
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
        return False
    else:
        for idx, name in enumerate(names, start=1):
            print(f"{idx}. {name}")
    print()  # Add a blank line for better readability
    return True

def get_user_choice(prompt, valid_choices):
    """
    Gets user input and validates it against valid choices.
    """
    while True:
        try:
            choice = input(prompt).strip().lower()
            if choice in valid_choices:
                return choice
            else:
                print(f"Invalid choice. Please enter one of: {', '.join(valid_choices)}")
        except KeyboardInterrupt:
            print("\nOperation cancelled by user.")
            sys.exit(0)

def get_number_choice(prompt, max_number):
    """
    Gets a number choice from user within valid range.
    """
    while True:
        try:
            choice = input(prompt).strip()
            if choice.lower() == 'q':
                return None
            
            num = int(choice)
            if 1 <= num <= max_number:
                return num
            else:
                print(f"Invalid number. Please enter a number between 1 and {max_number}, or 'q' to quit.")
        except ValueError:
            print("Invalid input. Please enter a number or 'q' to quit.")
        except KeyboardInterrupt:
            print("\nOperation cancelled by user.")
            sys.exit(0)

def remove_agent(agent_name):
    """
    Removes an agent using the orchestrate CLI command.
    """
    try:
        # For agents, we need to specify the kind. Assuming 'native' as default
        # You might need to adjust this based on your agent types
        cmd = ["orchestrate", "agents", "remove", "--name", agent_name, "--kind", "native"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✓ Successfully removed agent: {agent_name}")
        if result.stdout:
            print(f"Output: {result.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error removing agent '{agent_name}': {e}")
        if e.stderr:
            print(f"Error details: {e.stderr}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error removing agent '{agent_name}': {e}")
        return False

def remove_tool(tool_name):
    """
    Removes a tool using the orchestrate CLI command.
    """
    try:
        cmd = ["orchestrate", "tools", "remove", "-n", tool_name]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✓ Successfully removed tool: {tool_name}")
        if result.stdout:
            print(f"Output: {result.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ Error removing tool '{tool_name}': {e}")
        if e.stderr:
            print(f"Error details: {e.stderr}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error removing tool '{tool_name}': {e}")
        return False

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

    print("=== Watsonx Orchestrate Resource Cleanup Tool ===\n")

    # Ask user what type of resource to remove
    resource_choice = get_user_choice(
        "What type of resource do you want to remove?\n"
        "Enter 'agent' for agents, 'tool' for tools, or 'q' to quit: ",
        ['agent', 'tool', 'q']
    )

    if resource_choice == 'q':
        print("Goodbye!")
        sys.exit(0)

    if resource_choice == 'agent':
        print("\n" + "="*50)
        has_items = list_and_enumerate(agents_sorted, 'Available Agents to Remove')
        
        if not has_items:
            print("No agents found to remove.")
            return

        choice_num = get_number_choice(
            f"Enter the number of the agent to remove (1-{len(agents_sorted)}) or 'q' to quit: ",
            len(agents_sorted)
        )
        
        if choice_num is None:
            print("Operation cancelled.")
            return

        selected_agent = agents_sorted[choice_num - 1]
        
        # Confirm removal
        confirm = get_user_choice(
            f"Are you sure you want to remove agent '{selected_agent}'? (y/n): ",
            ['y', 'yes', 'n', 'no']
        )
        
        if confirm in ['y', 'yes']:
            print(f"\nRemoving agent: {selected_agent}")
            remove_agent(selected_agent)
        else:
            print("Agent removal cancelled.")

    elif resource_choice == 'tool':
        print("\n" + "="*50)
        has_items = list_and_enumerate(tools_sorted, 'Available Tools to Remove')
        
        if not has_items:
            print("No tools found to remove.")
            return

        choice_num = get_number_choice(
            f"Enter the number of the tool to remove (1-{len(tools_sorted)}) or 'q' to quit: ",
            len(tools_sorted)
        )
        
        if choice_num is None:
            print("Operation cancelled.")
            return

        selected_tool = tools_sorted[choice_num - 1]
        
        # Confirm removal
        confirm = get_user_choice(
            f"Are you sure you want to remove tool '{selected_tool}'? (y/n): ",
            ['y', 'yes', 'n', 'no']
        )
        
        if confirm in ['y', 'yes']:
            print(f"\nRemoving tool: {selected_tool}")
            remove_tool(selected_tool)
        else:
            print("Tool removal cancelled.")

if __name__ == "__main__":
    main()