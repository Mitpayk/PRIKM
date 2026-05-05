pipeline {
    agent any

    stages {
        stage('Start') {
            steps {
                echo 'Starting custom pipeline'
            }
        }

        stage('Stop old container') {
            steps {
                sh 'docker rm -f my_nginx || true'
            }
        }
        stage('Free port 80') {
            steps {
                sh 'docker stop $(docker ps -q) || true'
            }
        }

        stage('Build Image') {
            steps {
                sh 'docker build -t nginx/custom:latest .'
                sh "docker tag prikm Mitpayk/prikm:latest"
                sh "docker tag prikm Mitpayk/prikm:$BUILD_NUMBER"
            }
        }
        stage('Push to DockerHub') {
            steps {
                withDockerRegistry([ credentialsId: "mitpayk/prikm", url: "" ]) {
                    sh "docker push Mitpayk/prikm:latest"
                    sh "docker push Mitpayk/prikm:${BUILD_NUMBER}"
                }
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker run -d --name my_nginx -p 80:80 nginx/custom:latest'
            }
        }

        stage('Check Running Containers') {
            steps {
                sh 'docker ps'
            }
        }

        stage('Test Page') {
            steps {
                sh 'curl localhost:80'
            }
        }
    }
}       
