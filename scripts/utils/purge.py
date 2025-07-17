# purge.py

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

def remove_agent(agent_name):
    """
    Removes an agent using the orchestrate CLI command.
    """
    try:
        # For agents, we need to specify the kind. Assuming 'native' as default
        # You might need to adjust this based on your agent types
        cmd = ["orchestrate", "agents", "remove", "--name", agent_name, "--kind", "native"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"  ✓ Successfully removed agent: {agent_name}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  ✗ Error removing agent '{agent_name}': {e}")
        if e.stderr:
            print(f"    Error details: {e.stderr}")
        return False
    except Exception as e:
        print(f"  ✗ Unexpected error removing agent '{agent_name}': {e}")
        return False

def remove_tool(tool_name):
    """
    Removes a tool using the orchestrate CLI command.
    """
    try:
        cmd = ["orchestrate", "tools", "remove", "-n", tool_name]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"  ✓ Successfully removed tool: {tool_name}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  ✗ Error removing tool '{tool_name}': {e}")
        if e.stderr:
            print(f"    Error details: {e.stderr}")
        return False
    except Exception as e:
        print(f"  ✗ Unexpected error removing tool '{tool_name}': {e}")
        return False

def remove_all_agents(agent_names):
    """
    Removes all agents from the provided list.
    """
    if not agent_names:
        print("No agents found to remove.")
        return True

    print(f"\nRemoving {len(agent_names)} agents...")
    success_count = 0
    failed_count = 0

    for agent_name in agent_names:
        if remove_agent(agent_name):
            success_count += 1
        else:
            failed_count += 1

    print(f"\nAgent removal summary:")
    print(f"  ✓ Successfully removed: {success_count}")
    print(f"  ✗ Failed to remove: {failed_count}")
    
    return failed_count == 0

def remove_all_tools(tool_names):
    """
    Removes all tools from the provided list.
    """
    if not tool_names:
        print("No tools found to remove.")
        return True

    print(f"\nRemoving {len(tool_names)} tools...")
    success_count = 0
    failed_count = 0

    for tool_name in tool_names:
        if remove_tool(tool_name):
            success_count += 1
        else:
            failed_count += 1

    print(f"\nTool removal summary:")
    print(f"  ✓ Successfully removed: {success_count}")
    print(f"  ✗ Failed to remove: {failed_count}")
    
    return failed_count == 0

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

    print("=== Watsonx Orchestrate Resource PURGE Tool ===")
    print("⚠️  WARNING: This tool will remove ALL selected resources! ⚠️\n")

    # Show current resources
    print("Current Resources:")
    print("="*50)
    list_and_enumerate(agents_sorted, 'Available Agents')
    list_and_enumerate(tools_sorted, 'Available Tools')

    # Ask user what type of resource to remove
    resource_choice = get_user_choice(
        "What do you want to purge?\n"
        "Enter 'agents' to remove all agents\n"
        "Enter 'tools' to remove all tools\n"
        "Enter 'both' to remove all agents and tools\n"
        "Enter 'q' to quit: ",
        ['agents', 'tools', 'both', 'q']
    )

    if resource_choice == 'q':
        print("Goodbye!")
        sys.exit(0)

    # Show what will be removed and ask for confirmation
    print("\n" + "="*60)
    print("⚠️  FINAL WARNING ⚠️")
    print("="*60)

    if resource_choice == 'agents':
        if not agents_sorted:
            print("No agents found to remove.")
            return
        print(f"You are about to PERMANENTLY REMOVE {len(agents_sorted)} agents:")
        for agent in agents_sorted:
            print(f"  - {agent}")
    
    elif resource_choice == 'tools':
        if not tools_sorted:
            print("No tools found to remove.")
            return
        print(f"You are about to PERMANENTLY REMOVE {len(tools_sorted)} tools:")
        for tool in tools_sorted:
            print(f"  - {tool}")
    
    elif resource_choice == 'both':
        if not agents_sorted and not tools_sorted:
            print("No agents or tools found to remove.")
            return
        print(f"You are about to PERMANENTLY REMOVE:")
        print(f"  • {len(agents_sorted)} agents")
        print(f"  • {len(tools_sorted)} tools")
        print("\nAgents to be removed:")
        for agent in agents_sorted:
            print(f"  - {agent}")
        print("\nTools to be removed:")
        for tool in tools_sorted:
            print(f"  - {tool}")

    print("\n" + "="*60)
    
    # Final confirmation
    confirm = get_user_choice(
        "Are you ABSOLUTELY SURE you want to proceed? This action CANNOT be undone!\n"
        "Type 'YES' (in capitals) to confirm, or anything else to cancel: ",
        ['YES', 'yes', 'y', 'n', 'no']
    )

    # normalize
    confirm = confirm.strip().upper()

    if confirm != 'YES':
        print("Purge operation cancelled. No resources were removed.")
        return

    # Perform the removal
    print("\n" + "="*60)
    print("🚀 Starting purge operation...")
    print("="*60)

    overall_success = True

    if resource_choice in ['agents', 'both']:
        print("\n🔥 PURGING ALL AGENTS...")
        agent_success = remove_all_agents(agents_sorted)
        overall_success = overall_success and agent_success

    if resource_choice in ['tools', 'both']:
        print("\n🔥 PURGING ALL TOOLS...")
        tool_success = remove_all_tools(tools_sorted)
        overall_success = overall_success and tool_success

    # Final summary
    print("\n" + "="*60)
    print("📋 PURGE OPERATION COMPLETE")
    print("="*60)
    
    if overall_success:
        print("✅ All selected resources were successfully removed!")
    else:
        print("⚠️  Some resources could not be removed. Check the errors above.")
        print("💡 You may need to:")
        print("   - Check your permissions")
        print("   - Verify the orchestrate CLI is working")
        print("   - Manually remove failed items")

    print("\n🎯 Tip: Run the list script again to verify the current state.")

if __name__ == "__main__":
    main()