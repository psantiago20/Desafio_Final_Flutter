#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE pitaya_user;
    CREATE DATABASE pitaya_post;
    CREATE DATABASE pitaya_group;
    CREATE DATABASE pitaya_library;
    CREATE DATABASE pitaya_mentorship;
    CREATE DATABASE pitaya_gamification;
    CREATE DATABASE notification_db;
    CREATE DATABASE pitaya_message;
EOSQL

echo "All Pitaya databases created successfully."
