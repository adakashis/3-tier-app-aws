pipeline {
  agent any
  environment {
    PROJECT_ID = credentials('gcp-project-id')
    CLUSTER_NAME = 'demo-cluster'
    REGION = 'us-central1'
  }
  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/GoogleCloudPlatform/microservices-demo.git', branch: 'main'
      }
    }
    stage('Terraform Init & Apply') {
      steps {
        dir('infra-gcp') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve'
        }
      }
    }
    stage('Build Docker Images') {
      steps {
        sh 'docker build -t gcr.io/$PROJECT_ID/microservices-demo .'
        sh 'docker push gcr.io/$PROJECT_ID/microservices-demo'
      }
    }
    stage('Deploy to GKE') {
      steps {
        sh '''
          gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
          kubectl apply -f infra-gcp/kubernetes/
        '''
      }
    }
    stage('Smoke Test') {
      steps {
        sh 'kubectl get pods'
        sh 'kubectl get svc'
      }
    }
  }
  post {
    success {
      echo "Deployment successful!"
    }
    failure {
      echo "Pipeline failed. Check logs."
    }
  }
}
