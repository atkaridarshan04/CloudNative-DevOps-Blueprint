pipeline {
    agent {label 'worker'}
    
    environment{
        SONAR_HOME = tool "sonar"
    }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }
    
    stages {
        stage('Workspace cleanup') {
            steps {
                script {
                    cleanWs()
                }
            }
        }
        
        stage('Code Checkout') {
            steps {
                git url: "https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint.git", branch: "begineer"
            }
        }
        
        stage('trivy file scan') {
            steps {
                sh "trivy fs --format table -o fs.html ."
                
            }
        }

        stage("OWASP: Dependency check"){
            steps{
                script{
                    dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'OWASP'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        
        stage('SonarQube: Code Analysis') {
            steps {
                withSonarQubeEnv("sonar"){
                sh "$SONAR_HOME/bin/sonar-scanner -Dsonar.projectName=bookstore -Dsonar.projectKey=bookstore -X"
                }
            }
        }
        
        stage("SonarQube: Code Quality Gates"){
            steps {
                timeout(time: 5, unit: "MINUTES"){
                waitForQualityGate abortPipeline: false
                }
            }
        }
        
        stage("Docker: Build Images") {
            steps {
                script {
                    sh '''
                    cd frontend
                    docker build -t atkaridarshan04/bookstore-frontend:${FRONTEND_DOCKER_TAG} .
                    '''
                }
                script {
                    sh '''
                    cd backend
                    docker build -t atkaridarshan04/bookstore-backend:${BACKEND_DOCKER_TAG} .
                    '''
                }   
            }
        }
        
        stage("Docker: Push images to DockerHub") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-token', passwordVariable: 'dockerhubpass', usernameVariable: 'dockerhubuser')]) {
                    sh "docker login -u ${dockerhubuser} -p ${dockerhubpass}"
                    }
                    sh "docker push atkaridarshan04/bookstore-frontend:${FRONTEND_DOCKER_TAG}"
                }
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-token', passwordVariable: 'dockerhubpass', usernameVariable: 'dockerhubuser')]) {
                    sh "docker login -u ${dockerhubuser} -p ${dockerhubpass}"
                    }
                    sh "docker push atkaridarshan04/bookstore-backend:${BACKEND_DOCKER_TAG}"
                }
            }
        }
    }

    post{
    success{
        archiveArtifacts artifacts: '*.xml', allowEmptyArchive: true, followSymlinks: false
        build job: "bookstore-cd", parameters: [
            string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
            string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }   
    }
}