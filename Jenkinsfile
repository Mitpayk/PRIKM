pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Code checked out by Jenkins'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
                sh 'terraform output -raw ansible_inventory > inventory.ini'
            }
        }

        stage('Ansible Deploy') {
            steps {
                sh 'ansible-playbook -i inventory.ini playbook.yml'
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'curl -f http://localhost:8081 || exit 1'
                sh 'curl -f http://localhost:9090 || exit 1'
                sh 'curl -f http://localhost:3000 || exit 1'
                echo 'All services are UP!'
            }
        }

    }

    post {
        failure {
            sh 'terraform destroy -auto-approve'
        }
        always {
            echo 'Pipeline finished!'
        }
    }
}
