pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        ECR_REGISTRY       = '<your-account-id>.dkr.ecr.us-west-2.amazonaws.com'
        WEB_IMAGE          = "${ECR_REGISTRY}/web"
        APP_IMAGE          = "${ECR_REGISTRY}/app"
        EKS_CLUSTER        = '3tier-eks'
        IMAGE_TAG          = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Images') {
            steps {
                withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                        docker build -t ${WEB_IMAGE}:${IMAGE_TAG} src/web/
                        docker build -t ${APP_IMAGE}:${IMAGE_TAG} src/app/
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        docker push ${WEB_IMAGE}:${IMAGE_TAG}
                        docker push ${APP_IMAGE}:${IMAGE_TAG}

                        docker tag ${WEB_IMAGE}:${IMAGE_TAG} ${WEB_IMAGE}:latest
                        docker tag ${APP_IMAGE}:${IMAGE_TAG} ${APP_IMAGE}:latest

                        docker push ${WEB_IMAGE}:latest
                        docker push ${APP_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                        aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER}

                        kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -
                        kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -

                        kubectl apply -f k8s/network-policy/network-policies.yaml

                        kubectl set image deployment/web-deployment web=${WEB_IMAGE}:${IMAGE_TAG} -n web
                        kubectl set image deployment/app-deployment app=${APP_IMAGE}:${IMAGE_TAG} -n app

                        kubectl apply -f k8s/ingress/ingress.yaml

                        kubectl rollout status deployment/web-deployment -n web --timeout=120s
                        kubectl rollout status deployment/app-deployment -n app --timeout=120s
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                    sh '''
                        kubectl get pods -n web
                        kubectl get pods -n app
                        kubectl get ingress -n web
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful! Build #${BUILD_NUMBER}"
        }
        failure {
            withAWS(credentials: 'amazon_aws', region: "${AWS_DEFAULT_REGION}") {
                sh '''
                    kubectl rollout undo deployment/web-deployment -n web
                    kubectl rollout undo deployment/app-deployment -n app
                '''
            }
        }
    }
}
