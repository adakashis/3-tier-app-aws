pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS = credentials('aws-jenkins-creds')   // Jenkins credential ID for AWS keys
        APP_NAME = 'my-aws-app'
        ACCOUNT_ID = '<your-aws-account-id>'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/<your-username>/<repo-name>.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'   // Example for Java; replace with npm, gradle, etc.
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh '''
                docker build -t $APP_NAME:$BUILD_NUMBER .
                docker tag $APP_NAME:$BUILD_NUMBER $ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$APP_NAME:$BUILD_NUMBER
                aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
                docker push $ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$APP_NAME:$BUILD_NUMBER
                '''
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir('infra-aws') {
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'curl -f http://<ALB-DNS-NAME>/health || exit 1'
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
