#!/bin/bash

# Wrapper script to run the Python chaos suite with the virtual environment

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    
    echo "Installing dependencies..."
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
fi

# Ensure the chaos-experiments directory exists
if [ ! -d "chaos-experiments" ]; then
    echo "Error: chaos-experiments directory not found!"
    echo "Please make sure the chaos experiment YAML files are in the chaos-experiments directory."
    exit 1
fi

# Check if the required YAML files exist
required_files=(
    "chaos-experiments/network-delay-chaos.yaml"
    "chaos-experiments/pod-failure-chaos.yaml"
    "chaos-experiments/cpu-stress-chaos.yaml"
    "chaos-experiments/memory-stress-chaos.yaml"
    "chaos-experiments/io-chaos.yaml"
    "chaos-experiments/chaos-workflow.yaml"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Warning: $file not found!"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo "Warning: $missing_files required files are missing."
    read -p "Do you want to continue anyway? (y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        echo "Aborting."
        exit 1
    fi
fi

# Activate virtual environment and run the Python script
source venv/bin/activate
./run_chaos_suite.py "$@"
deactivate 