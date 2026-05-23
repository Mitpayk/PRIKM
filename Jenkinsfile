pipeline {
    agent any

    parameters {
        choice(name: 'ACTION',
               choices: ['deploy', 'backup', 'restore', 'test-failover', 'teardown'],
               description: 'Що виконати')
    }

    environment {
        WORK_DIR = '"$WORKSPACE"'
    }

    stages {

        stage('Pre-flight') {
            steps {
                sh 'docker --version && docker compose version'
                sh 'chmod +x $WORK_DIR/*.sh'
                sh 'mkdir -p $WORK_DIR/backup'
            }
        }

        stage('Deploy') {
            when { expression { params.ACTION == 'deploy' } }
            steps {
                sh 'cd $WORK_DIR && docker compose up -d'
                sh 'sleep 20'
                sh 'cd $WORK_DIR && docker compose ps'
                sh '$WORK_DIR/init-replicaset.sh'
            }
        }

        stage('Backup') {
            when { expression { params.ACTION == 'backup' } }
            steps {
                sh '$WORK_DIR/backup.sh'
                sh 'ls -lh $WORK_DIR/backup/'
            }
        }

        stage('Restore') {
            when { expression { params.ACTION == 'restore' } }
            steps {
                sh '$WORK_DIR/restore.sh'
            }
        }

        stage('Test Failover') {
            when { expression { params.ACTION == 'test-failover' } }
            steps {
                sh '$WORK_DIR/test-failover.sh'
            }
        }

        stage('Teardown') {
            when { expression { params.ACTION == 'teardown' } }
            steps {
                sh 'cd $WORK_DIR && docker compose down -v'
            }
        }
    }

    post {
        always {
            sh 'docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}" || true'
        }
    }
}
