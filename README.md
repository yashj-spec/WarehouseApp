# Check CLI
sf --version

# Show connected orgs
sf org list

# Login
sf org login web

# Set default org
sf config set target-org yourUsername

# Check default org
sf config get target-org

# Show current org details
sf org display

# Open org
sf org open

# Retrieve latest metadata
sf project retrieve start --manifest manifest/package.xml

# Deploy all changes
sf project deploy start

# Deploy one class
sf project deploy start --source-dir force-app/main/default/classes/DuplicateContactService.cls

# Deploy all classes
sf project deploy start --source-dir force-app/main/default/classes

# Deploy triggers
sf project deploy start --source-dir force-app/main/default/triggers

# Run one test
sf apex run test --tests DuplicateContactServiceTest --synchronous

# Run one test with coverage
sf apex run test --tests DuplicateContactServiceTest --code-coverage --synchronous

# Run all tests
sf apex run test

# Get async test results
sf apex get test -i TEST_RUN_ID
