pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        INSTANCE_TYPE      = 't2.micro'
        KEY_NAME           = 'myjenkinsconnect'
        PATH               = "/usr/local/bin:${env.PATH}"
    }

    stages {

        stage('Terraform Apply') {
            steps {
                sh '''
                cd infra
                terraform init
                terraform apply -auto-approve
                '''
            }
        }

        stage('Deploy EC2') {
            steps {
                script {
                    // Fetch Terraform outputs
                    def subnet_id = sh(script: "cd infra && terraform output -raw subnet_id", returnStdout: true).trim()
                    def sg_id     = sh(script: "cd infra && terraform output -raw security_group_id", returnStdout: true).trim()
                    def ami_id    = sh(script: "cd infra && terraform output -raw ami_id", returnStdout: true).trim()

                    // Run AWS CLI commands
                    sh '''
                    INSTANCE_ID=$(aws ec2 run-instances \
                        --image-id ''' + ami_id + ''' \
                        --instance-type ''' + INSTANCE_TYPE + ''' \
                        --key-name ''' + KEY_NAME + ''' \
                        --security-group-ids ''' + sg_id + ''' \
                        --subnet-id ''' + subnet_id + ''' \
                        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=jenkins-ec2}]" \
                        --query "Instances[0].InstanceId" \
                        --output text)

                    echo "Instance ID: $INSTANCE_ID"

                    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

                    PUBLIC_IP=$(aws ec2 describe-instances \
                        --instance-ids $INSTANCE_ID \
                        --query "Reservations[0].Instances[0].PublicIpAddress" \
                        --output text)

                    echo "EC2 running at: $PUBLIC_IP"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ EC2 deployed successfully!"
        }
        failure {
            echo "❌ EC2 deployment failed!"
        }
    }
}
