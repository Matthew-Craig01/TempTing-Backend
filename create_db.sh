#!/bin/bash

DB_FILE="temp_ting.db"

echo "Creating database..."
sqlite3 $DB_FILE < create_db.sql

if [ $? -eq 0 ]; then
    echo "Database created successfully."
else
    echo "Error creating database."
    exit 1
fi
