#!/usr/bin/env bash

set -e

# Ensure we're in the project directory
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

# Check for Node.js
if ! which node > /dev/null 2>&1; then
    prompt_install "Node.js"
    echo "Installing Node.js and npm..."
    sudo apt-get update
    sudo apt-get install -y nodejs npm
fi

# Check npm
if ! which npm > /dev/null 2>&1; then
    echo "npm not found after Node.js installation. Please install npm manually or verify Node.js installation."
    exit 1
fi

# Check PostgreSQL
if ! which psql > /dev/null 2>&1; then
    prompt_install "PostgreSQL"
    echo "Installing PostgreSQL..."
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib
    # Start PostgreSQL if not running
    sudo service postgresql start
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

echo "Setup complete on Linux!"
