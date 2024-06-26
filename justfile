set dotenv-load 

default:
	just --list

# Run test suite in verbose mode with the gin server mode set to test
test $GIN_MODE="test":
	go test ./... -v

run:
	go run ./...

# Build the bin and place it at the relative path of bin/app
build:
	go build -v -o bin/app ./...

# Run the build. pass in a paramater to set the gin server mode. default is debug
run-build $GIN_MODE="debug":
	./bin/app

# Run linter
lint:
	golangci-lint run ./... --verbose

# Build docker image
build-image:
	docker build -t interface .

run-container port="9002":
	docker run -p {{port}}:$PASSMAN_PORT interface:latest


# Generate a .env file
gen-dotenv mode="debug" port="9002" pass-gen-url="http://localhost:8080" db-user="passMan2" db-host="localhost" db-password="passManPassword":
	touch .env
	echo "GIN_MODE=\"{{mode}}\"" >> .env
	echo "PASSMAN_PORT=\"{{port}}\"" >> .env
	echo "PASSMAN_PASS_GEN_URL=\"{{pass-gen-url}}\"" >> .env
	echo "DB_USER=\"{{db-user}}\"" >> .env
	echo "DB_HOST=\"{{db-host}}\"" >> .env
	echo "DB_PASSWORD=\"{{db-password}}\"" >> .env

# Create the passMan db user. pass in a mysql root user's login
inital-db-setup username="root" password="password":
	echo "Create db"
	mysql -u {{username}} -p"{{password}}" -e "CREATE DATABASE passMan_db;"
	echo "creating user"
	mysql -u {{username}} -p"{{password}}" -e "CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';"
	echo "Adding privileges"
	mysql -u {{username}} -p"{{password}}" -e "GRANT ALL PRIVILEGES ON passMan_db.* TO '${DB_USER}'@'${DB_HOST}';"

run-sql file:
	#!/usr/bin/env bash
	set -euxo pipefail
	cd sql/
	mysql --host=${DB_HOST} --user=${DB_USER} --password=${DB_PASSWORD} passMan_db < {{file}}

sql-create-tables:
	just run-sql create_tables.sql
