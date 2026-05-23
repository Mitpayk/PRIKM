pipeline {
    agent any

    parameters {
        choice(name: 'ACTION',
               choices: ['deploy', 'backup', 'restore', 'test-failover', 'teardown'],
               description: 'Що виконати')
    }

    stages {

        stage('Pre-flight') {
            steps {
                sh 'docker --version && docker compose version'
                sh 'chmod +x *.sh'
                sh 'mkdir -p backup'
            }
        }

        stage('Deploy') {
            when { expression { params.ACTION == 'deploy' } }
            steps {
                sh 'docker compose up -d'
                sh 'sleep 20'
                sh 'docker compose ps'
                sh 'bash init-replicaset.sh'
            }
        }

        stage('Backup') {
            when { expression { params.ACTION == 'backup' } }
            steps {
                sh 'bash backup.sh'
                sh 'ls -lh backup/'
            }
        }

        stage('Restore') {
            when { expression { params.ACTION == 'restore' } }
            steps {
                sh 'bash restore.sh'
            }
        }

        stage('Test Failover') {
            when { expression { params.ACTION == 'test-failover' } }
            steps {
                sh 'bash test-failover.sh'
            }
        }

        stage('Teardown') {
            when { expression { params.ACTION == 'teardown' } }
            steps {
                sh 'docker compose down -v'
            }
        }
    }

    post {
        always {
            sh 'docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}" || true'
        }
    }
}
