#!/bin/bash
# Python virtual environment management
# @python, @venv, @pip

# alias venv='python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip wheel'
# Create a new virtual environment
# Create a new virtual environment
venv() {
    local name=${1:-.venv}
    local version=$2

    if [[ $name == 3.* ]]; then
        version=$name
        name=.venv
    fi

    if [ -z "$version" ]; then
        python -m venv $name
    elif [[ $version =~ ^[0-9]+\.[0-9]+$ ]]; then
        python${version} -m venv $name
    else
        echo "Invalid Python version format. Using system default."
        python -m venv $name
    fi
    
    source $name/bin/activate && pip install --upgrade pip wheel
    echo "Virtual environment created in ./$name"
}

# Activate the virtual environment
alias venva='source .venv/bin/activate && echo "Activated virtual environment"'

# alias venva-jlab="jlab env active .venv"
# pip install ipykernel
# python -m ipykernel install --user --name=myenv

function jlab--kernel-create-from-project-venv() {
    # Use the provided argument or default to the current directory
    local project_dir="${1:-$(pwd)}"

    # Navigate to the project directory
    cd "$project_dir" || return

    # Activate the virtual environment
    source .venv/bin/activate

    # Install ipykernel if it's not already installed
    if ! pip show ipykernel > /dev/null; then
        pip install ipykernel
    fi

    # Get the project directory name
    local project_name=$(basename "$project_dir")

    # Check if the kernel already exists
    if jupyter kernelspec list | grep -q "$project_name"; then
        read -p "Kernel '$project_name' already exists. Do you want to override it? (y/n): " choice
        case "$choice" in
            y|Y ) 
                echo "Overriding kernel '$project_name'."
                jupyter kernelspec remove "$project_name" --yes  # Remove the existing kernel
                ;;
            n|N ) 
                echo "No changes made. Exiting."
                return 1  # Exit without making changes
                ;;
            * ) 
                echo "Invalid choice. Exiting."
                return 1  # Exit on invalid input
                ;;
        esac
    fi

    # Register the virtual environment as a Jupyter kernel
    python -m ipykernel install --user --name="$project_name"

    echo "Kernel '$project_name' created and activated."
}
alias venva-jupyterlab-kernel-create-from-project-venv='jlab--kernel-create-from-project-venv'

# Deactivate the virtual environment
alias venvd='deactivate && echo "Deactivated virtual environment"'

# Upgrade pip and wheel in the virtual environment
alias venvu='pip install --upgrade pip wheel'

# Remove the virtual environment
alias venvrm='deactivate && rm -rf .venv'

# Check Python version in the virtual environment
alias venvv='python --version'

# Install dependencies from requirements.txt
alias venvi='pip install -r requirements.txt && echo "Installed dependencies from requirements.txt"'

# List installed packages in the virtual environment
alias venvlist='pip list'

# Update all installed packages
alias venvup='pip freeze | xargs -n1 pip install -U'

alias venvreq='pip freeze > requirements.txt'



# Show information about the virtual environment
venv_info() {
    if [ -d ".venv" ]; then
        echo "Virtual Environment Information:"
        echo "--------------------------------"
        echo "Python Executable: $(.venv/bin/python --version)"
        echo "Installed Packages:"
        pip list
        echo "Virtual Environment Location: ./.venv"
        echo "Python Version: $(.venv/bin/python --version)"
        echo "OS: $(uname -o)"
        echo "Shell: $(echo $SHELL)"
        echo "User: $(whoami)"
    else
        echo "No virtual environment found. Please create one using 'venv'."
    fi
}


# Usage instructions for the aliases
function venv_help() {
    echo "Available commands:"
    echo "  venv      : Create a new virtual environment"
    echo "  venva     : Activate the virtual environment"
    echo "  venvd     : Deactivate the virtual environment"
    echo "  venvu     : Upgrade pip and wheel"
    echo "  venvrm    : Remove the virtual environment"
    echo "  venvv     : Check Python version in the virtual environment"
    echo "  venvi     : Install dependencies from requirements.txt"
    echo "  venvup    : Update all installed packages"
    echo "  venvreq   : Save installed packages to requirements.txt"
    echo "  venvlist  : List installed packages"
    echo "  venv_info : Show information about the virtual environment"
    echo "  venv_help : Show this help message"
}


# Seamlessly handle errors and try to pip-install [module name] modules:
# - NameError: name '[module name]' is not defined. Did you forget to import 'os'?
# - ModuleNotFoundError: No module named '[module name]'
# - ImportError: `[module name]` not installed. Please install using `pip install duckduckgo-search`
function p() {
    local script="$1"
    local venv_dir=".venv"

    # Step 1: Check if .venv directory exists, if not, create it
    if [ ! -d "$venv_dir" ]; then
        python3 -m venv "$venv_dir"
    fi

    # Activate virtual environment
    source "$venv_dir/bin/activate"

    # Step 2: Attempt to execute the script
    python3 "$script" 2>&1 | while read -r line; do
        # Check for common error patterns
        if [[ "$line" == *"ModuleNotFoundError: No module named"* ]]; then
            module=$(echo "$line" | sed -n "s/.*No module named '\([^']*\)'.*/\1/p")
            echo "Module '$module' is missing. Installing..."
            pip install "$module"
        elif [[ "$line" == *"ImportError:"* ]]; then
            module=$(echo "$line" | sed -n "s/.*ImportError: \`*\([^`]*\)`* not installed.*/\1/p")
            echo "Module '$module' is required. Installing..."
            pip install "$module"
        elif [[ "$line" == *"NameError:"* ]]; then
            module=$(echo "$line" | sed -n "s/.*Did you forget to import '\([^']*\)'.*/\1/p")
            echo "Module '$module' is not defined. Installing..."
            pip install "$module"
        else
            echo "$line"
        fi
    done

    # Deactivate the virtual environment
    deactivate
}
