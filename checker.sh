#!/bin/bash

# Define the version to check
VERSION="3.11.9"
PYTHON_DIR="/Applications/Python 3.11"

#!/bin/bash

# Define the version to check
VERSION="3.11.9"
PYTHON_BIN=$(which python3)

# Function to check if the directory exists and the version is correct
check_python_version() {
    if [ -d "$PYTHON_DIR" ]; then
        if command -v python3 &> /dev/null; then
            INSTALLED_VERSION=$($PYTHON_BIN --version 2>&1 | awk '{print $2}')
            if [ "$INSTALLED_VERSION" == "$VERSION" ]; then
                echo "Python $VERSION is already installed."
                exit 1
            else
                echo "Installed Python version is $INSTALLED_VERSION. Need $VERSION."
            fi
        else
            echo "Python $VERSION is not installed."
        fi
    else
        echo "Python $VERSION is not installed."
    fi
}

# Function to download and install Python
download_and_install_python() {
    echo "Downloading Python $VERSION..."
    curl -O "https://www.python.org/ftp/python/$VERSION/python-$VERSION-macos11.pkg"
    echo "Download complete."

    echo "Installing Python $VERSION..."
    sudo installer -pkg "python-$VERSION-macos11.pkg" -target /

    if [ $? -eq 0 ]; then
        echo "Python $VERSION installed successfully."
    else
        echo "Installation failed."
    fi
    exit 1
}

# Main script execution
check_python_version || download_and_install_python