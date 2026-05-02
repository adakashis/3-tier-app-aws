pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDS = credentials('aws-jenkins-creds')
    }
    stages {
        stage('Deploy') {
            steps {
                withAWS(credentials: 'aws-jenkins-creds', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                    aws s3 ls
                    # or terraform apply, ecs deploy, etc.
                    '''
                }
            }
        }
    }
}
