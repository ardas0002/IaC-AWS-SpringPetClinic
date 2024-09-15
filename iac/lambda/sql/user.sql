-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS petclinic;

-- Set the default character set and collation for the database
ALTER DATABASE petclinic
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Create a new user if it doesn't exist
CREATE USER IF NOT EXISTS 'username'@'%' IDENTIFIED BY 'password';

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON petclinic.* TO 'username'@'%';

-- Flush privileges to ensure the changes take effect
FLUSH PRIVILEGES;