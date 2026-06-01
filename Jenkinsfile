pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'backup', 'restore', 'test-failover', 'teardown'],
            description: 'Оберіть дію'
        )
        string(
            name: 'RESTORE_FILE',
            defaultValue: '',
            description: 'Файл для restore (порожньо = останній backup)'
        )
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
                sh '''
                    kill $(cat monitor.pid 2>/dev/null) 2>/dev/null || true
                    nohup bash monitor.sh > monitor.log 2>&1 &
                    echo $! > monitor.pid
                    echo "[+] Monitor started (PID $(cat monitor.pid))"
                '''
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
                sh """
                    if [ -n "${params.RESTORE_FILE}" ]; then
                        bash restore.sh backup/${params.RESTORE_FILE}
                    else
                        bash restore.sh
                    fi
                """
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
                sh '''
                    kill $(cat monitor.pid 2>/dev/null) 2>/dev/null || true
                    rm -f monitor.pid
                    echo "[+] Monitor stopped"
                '''
                sh 'docker compose down -v'
            }
        }
    }

    post {
        success {
            notifyEvents(
                message: "Build ${BUILD_NUMBER} [${params.ACTION}] SUCCESS",
                token: 'ct-q5dageamlhvfjlsdlvlanmkxqwcfx'
            )
        }
        failure {
            notifyEvents(
                message: "Build ${BUILD_NUMBER} [${params.ACTION}] FAILED",
                token: 'ct-q5dageamlhvfjlsdlvlanmkxqwcfx'
            )
        }
        always {
            sh 'docker ps --filter "name=mongo" --format "table {{.Names}}\t{{.Status}}" || true'
        }
    }
}
