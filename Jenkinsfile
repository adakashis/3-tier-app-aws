pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        INSTANCE_TYPE      = 't2.micro'
        AMI_ID             = 'ami-0c55b159cbfafe1f0'  // Amazon Linux 2 us-west-2
        KEY_NAME           = '<your-key-pair-name>'
        SECURITY_GROUP     = '<your-security-group-id>'
        SUBNET_ID          = '<your-subnet-id>'
    }

    stages {

        stage('Deploy EC2') {
            steps {
                withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                        INSTANCE_ID=$(aws ec2 run-instances \
                            --image-id ${AMI_ID} \
                            --instance-type ${INSTANCE_TYPE} \
                            --key-name ${KEY_NAME} \
                            --security-group-ids ${SECURITY_GROUP} \
                            --subnet-id ${SUBNET_ID} \
                            --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-ec2}]' \
                            --query 'Instances[0].InstanceId' \
                            --output text)

                        echo "EC2 Instance ID: $INSTANCE_ID"

                        aws ec2 wait instance-running --instance-ids $INSTANCE_ID

                        PUBLIC_IP=$(aws ec2 describe-instances \
                            --instance-ids $INSTANCE_ID \
                            --query 'Reservations[0].Instances[0].PublicIpAddress' \
                            --output text)

                        echo "EC2 is running at: $PUBLIC_IP"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "EC2 deployed successfully!"
        }
        failure {
            echo "EC2 deployment failed!"
        }
    }
}
