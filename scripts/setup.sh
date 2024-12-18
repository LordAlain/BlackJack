#!/usr/bin/env bash

set -e

# Ensure we're in the project directory (the parent of scripts/)
cd "$(dirname "$0")/.."

# Function to prompt the user before installing packages
prompt_install() {
    local pkg_name=$1
    echo "It seems $pkg_name is not installed."
    read -p "Would you like to install $pkg_name now? (y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        return 0
    else
        echo "Cannot continue without $pkg_name. Exiting."
        exit 1
    fi
}

# Ensure Homebrew is installed
if ! which brew > /dev/null 2>&1; then
    echo "Homebrew is not installed. Would you like to install Homebrew now?"
    read -p "(y/n): " brew_choice
    if [[ $brew_choice == "y" || $brew_choice == "Y" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Update PATH for Apple Silicon or Intel Macs if needed
        if [ "$(uname -m)" = "arm64" ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "Cannot proceed without Homebrew. Exiting."
        exit 1
    fi
fi

# Check Node.js
if ! which node > /dev/null 2>&1; then
    prompt_install "Node.js"
    echo "Installing Node.js..."
    brew install node
fi

# Check npm (should come with Node.js)
if ! which npm > /dev/null 2>&1; then
    echo "npm not found even after Node.js installation. Check your Node.js install."
    exit 1
fi

# Check PostgreSQL
if ! which psql > /dev/null 2>&1; then
    prompt_install "PostgreSQL"
    echo "Installing PostgreSQL..."
    brew install postgresql
    # Start PostgreSQL service
    brew services start postgresql
fi

# Copy .env.example to .env if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env file created from .env.example. Please edit it with your DB credentials and secrets if needed."
else
    echo ".env already exists. Skipping copy."
fi

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Ensure DB variables are set
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "Error: DB_NAME or DB_USER not set in .env. Please configure your .env file."
    exit 1
fi

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo "Installing Node.js dependencies..."
npm install

echo "Checking if database $DB_NAME exists..."
if ! psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "Database $DB_NAME does not exist. Creating..."
    createdb -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME"
fi

echo "Initializing database schema..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -f scripts/init_db.sql

echo "Setup complete on macOS!"
