pipeline {
    agent any

    parameters {
        string(name: 'VERSION', defaultValue: '${BUILD_NUMBER}', description: 'Docker tag')
        booleanParam(name: 'BUILD_IMAGE', defaultValue: true, description: '')
        booleanParam(name: 'PUSH_IMAGE', defaultValue: true, description: '')
    }

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
                sh 'docker ps -q | xargs -r docker stop'
            }
        }

        stage('Build Image') {
    when {
        expression { params.BUILD_IMAGE }
    }
    steps {
        sh "docker build -t prikm:${params.VERSION} ."
        sh "docker tag prikm:${params.VERSION} mitpayk/prikm:latest"
        sh "docker tag prikm:${params.VERSION} mitpayk/prikm:${params.VERSION}"
    }
}
        stage('Push to DockerHub') {
    when {
        expression { params.PUSH_IMAGE }
    }
    steps {
        withDockerRegistry([ credentialsId: "docker", url: "" ]) {
            sh "docker push mitpayk/prikm:latest"
            sh "docker push mitpayk/prikm:${params.VERSION}"
        }
    }
}
        stage('Run Container') {
    steps {
        sh 'docker rm -f my_nginx || true'
        sh 'docker run -d --name my_nginx -p 80:80 prikm:latest'
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
       stage('Debug Info') {
            steps {
                sh 'echo "BUILD NUMBER = ${BUILD_NUMBER}"'
                sh 'docker images'
            }
        }
    }
       post {
            success {
                notifyEvents(
                message: "Build ${BUILD_NUMBER} SUCCESS",
                token: 'ct-q5dageamlhvfjlsdlvlanmkxqwcfx'
        )
    }
       failure {
                notifyEvents(
                message: "Build ${BUILD_NUMBER} FAILED",
                token: 'ct-q5dageamlhvfjlsdlvlanmkxqwcfx'
        )
      }
    }
}       
 
