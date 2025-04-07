#!/bin/bash
# Script to deploy Dating App AI Assistant to a cloud provider

# Set environment variables
export FLASK_APP=web_app.py
export FLASK_ENV=production
export FLASK_SECRET_KEY=$(openssl rand -hex 32)

# Check if OpenAI API key is provided
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set."
    echo "Please set it with: export OPENAI_API_KEY=your_api_key"
    exit 1
fi

# Function to deploy to Digital Ocean
deploy_to_digital_ocean() {
    echo "Deploying to Digital Ocean..."
    
    # Check if doctl is installed
    if ! command -v doctl &> /dev/null; then
        echo "doctl is not installed. Please install it first."
        echo "Visit: https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi
    
    # Check if user is authenticated
    if ! doctl account get &> /dev/null; then
        echo "Please authenticate with Digital Ocean first using:"
        echo "doctl auth init"
        exit 1
    fi
    
    # Create app spec file
    cat > app.yaml << EOL
name: dating-app-ai-assistant
region: nyc
services:
  - name: web
    github:
      repo: your-github-username/dating-app-ai-assistant
      branch: main
    build_command: pip install -r requirements.txt
    run_command: gunicorn --bind 0.0.0.0:8080 web_app:app
    envs:
      - key: FLASK_APP
        value: web_app.py
      - key: FLASK_ENV
        value: production
      - key: FLASK_SECRET_KEY
        value: ${FLASK_SECRET_KEY}
      - key: OPENAI_API_KEY
        value: ${OPENAI_API_KEY}
EOL
    
    # Create the app
    doctl apps create --spec app.yaml
    
    echo "App deployed to Digital Ocean!"
    echo "Check your Digital Ocean dashboard for the app URL."
}

# Function to deploy to Heroku
deploy_to_heroku() {
    echo "Deploying to Heroku..."
    
    # Check if Heroku CLI is installed
    if ! command -v heroku &> /dev/null; then
        echo "Heroku CLI is not installed. Please install it first."
        echo "Visit: https://devcenter.heroku.com/articles/heroku-cli"
        exit 1
    fi
    
    # Check if user is logged in
    if ! heroku whoami &> /dev/null; then
        echo "Please log in to Heroku first using:"
        echo "heroku login"
        exit 1
    fi
    
    # Create Heroku app
    APP_NAME="dating-app-ai-assistant-$(date +%s)"
    heroku create $APP_NAME
    
    # Create Procfile
    echo "web: gunicorn web_app:app" > Procfile
    
    # Set environment variables
    heroku config:set FLASK_APP=web_app.py -a $APP_NAME
    heroku config:set FLASK_ENV=production -a $APP_NAME
    heroku config:set FLASK_SECRET_KEY=$FLASK_SECRET_KEY -a $APP_NAME
    heroku config:set OPENAI_API_KEY=$OPENAI_API_KEY -a $APP_NAME
    
    # Deploy to Heroku
    git init
    heroku git:remote -a $APP_NAME
    git add .
    git commit -m "Initial deployment"
    git push heroku master
    
    echo "App deployed to Heroku!"
    echo "Your app is available at: https://$APP_NAME.herokuapp.com"
}

# Function to deploy to AWS Elastic Beanstalk
deploy_to_aws() {
    echo "Deploying to AWS Elastic Beanstalk..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install it first."
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check if EB CLI is installed
    if ! command -v eb &> /dev/null; then
        echo "EB CLI is not installed. Please install it first."
        echo "Run: pip install awsebcli"
        exit 1
    fi
    
    # Check if user is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Please configure AWS CLI first using:"
        echo "aws configure"
        exit 1
    fi
    
    # Initialize EB application
    eb init -p python-3.10 dating-app-ai-assistant
    
    # Create .ebextensions configuration
    mkdir -p .ebextensions
    cat > .ebextensions/01_flask.config << EOL
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_APP: web_app.py
    FLASK_ENV: production
    FLASK_SECRET_KEY: ${FLASK_SECRET_KEY}
    OPENAI_API_KEY: ${OPENAI_API_KEY}
  aws:elasticbeanstalk:container:python:
    WSGIPath: web_app:app
EOL
    
    # Create EB environment
    eb create dating-app-ai-assistant-env
    
    echo "App deployed to AWS Elastic Beanstalk!"
    echo "Check your AWS Elastic Beanstalk console for the app URL."
}

# Function to deploy locally with Docker
deploy_locally() {
    echo "Deploying locally with Docker..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install it first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Please install it first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Create .env file
    cat > .env << EOL
FLASK_APP=web_app.py
FLASK_ENV=production
FLASK_SECRET_KEY=${FLASK_SECRET_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
EOL
    
    # Build and start containers
    docker-compose up -d --build
    
    echo "App deployed locally with Docker!"
    echo "Your app is available at: http://localhost:80"
}

# Main menu
echo "Dating App AI Assistant Deployment"
echo "=================================="
echo "Select deployment target:"
echo "1) Digital Ocean"
echo "2) Heroku"
echo "3) AWS Elastic Beanstalk"
echo "4) Local Docker deployment"
echo "5) Exit"
read -p "Enter your choice (1-5): " choice

case $choice in
    1) deploy_to_digital_ocean ;;
    2) deploy_to_heroku ;;
    3) deploy_to_aws ;;
    4) deploy_locally ;;
    5) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid choice. Exiting..."; exit 1 ;;
esac
