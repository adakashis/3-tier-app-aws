pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        INSTANCE_TYPE      = 't2.micro'
        AMI_ID             = 'ami-09d7e465726bef039'
        KEY_NAME           = 'myjenkinsconnect'
        SECURITY_GROUP     = 'sg-06daac0b60d005988'
        SUBNET_ID          = 'subnet-00e11eec59234e7b6'
        PATH               = "/usr/local/bin:${env.PATH}"
    }

    stages {

        stage('Deploy EC2') {
            steps {
                withCredentials([aws(
                    credentialsId: 'amazon_aws',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
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

                        echo "Instance ID: $INSTANCE_ID"

                        aws ec2 wait instance-running --instance-ids $INSTANCE_ID

                        PUBLIC_IP=$(aws ec2 describe-instances \
                            --instance-ids $INSTANCE_ID \
                            --query 'Reservations[0].Instances[0].PublicIpAddress' \
                            --output text)

                        echo "EC2 running at: $PUBLIC_IP"
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
