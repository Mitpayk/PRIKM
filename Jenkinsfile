pipeline {
    agent any

    stages {

        stage('Infrastructure Provisioning') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
                sh 'terraform output -raw server_ip > server_ip.txt'
                sh 'terraform output -raw ansible_inventory > inventory.ini'
            }
        }

        stage('Configuration & Deploy') {
            steps {
                sh 'ansible-playbook -i inventory.ini playbook.yml'
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
