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
            def subnet_id = sh(script: "cd infra && terraform output -raw subnet_id", returnStdout: true).trim()
            def sg_id     = sh(script: "cd infra && terraform output -raw security_group_id", returnStdout: true).trim()
            def ami_id    = sh(script: "cd infra && terraform output -raw ami_id", returnStdout: true).trim()

            sh """
            INSTANCE_ID=$(aws ec2 run-instances \
                --image-id ${ami_id} \
                --instance-type ${INSTANCE_TYPE} \
                --key-name ${KEY_NAME} \
                --security-group-ids ${sg_id} \
                --subnet-id ${subnet_id} \
                --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-ec2}]' \
                --query 'Instances[0].InstanceId' \
                --output text)

            aws ec2 wait instance-running --instance-ids $INSTANCE_ID
            aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text
            """
        }
    }
}
