#!/bin/bash

echo "Running Docker Containers with Clickable Links:"
echo "-----------------------------------------------"
docker ps --format "{{.Names}}\t{{.Ports}}" | while IFS=$'\t' read -r name ports; do
    echo "Container: $name"
    
    # Extract and print host ports with clickable links
    echo "$ports" | grep -oP '0\.0\.0\.0:\d+' | while read -r port; do
        host_port=$(echo "$port" | cut -d':' -f2)
        echo "  ➤ http://localhost:$host_port"
    done

    echo ""
done
