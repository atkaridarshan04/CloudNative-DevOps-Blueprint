pipeline {
    agent any

    environment {
        SONAR_HOME = tool "sonar"
        DOCKER_USERNAME = "atkaridarshan04"
        GIT_REPO_URL = "https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint.git"
        GIT_BRANCH = "prod"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'latest', description: 'Docker tag for frontend image')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'latest', description: 'Docker tag for backend image')
    }

    stages {

        /* --------------------- CLEAN + CHECKOUT --------------------- */
        stage('Clean Workspace') {
            steps {
                cleanWs()
                echo "Workspace cleaned"
            }
        }

        stage('Checkout Code') {
            steps {
                git url: "${GIT_REPO_URL}", branch: "${GIT_BRANCH}"
                echo "Code checked out from GitHub"
            }
        }

        /* --------------------- SECURITY SCANS --------------------- */
        stage('Trivy File Scan') {
            steps {
                sh "trivy fs --format table -o trivy-report.html ."
                echo "Trivy filesystem scan completed"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("sonar") {
                    sh """
                        ${SONAR_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=bookstore \
                        -Dsonar.projectKey=bookstore \
                        -Dsonar.sources=src
                    """
                }
                echo "SonarQube analysis completed"
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
                echo "Quality gate check completed"
            }
        }

        /* --------------------- DOCKER BUILD + PUSH --------------------- */
        stage('Build Frontend Image') {
            steps {
                dir('src/frontend') {
                    sh """
                        echo "Building frontend Docker image..."
                        docker build -t ${DOCKER_USERNAME}/bookstore-frontend:${params.FRONTEND_DOCKER_TAG} .
                    """
                }
                echo "Frontend image built successfully"
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('src/backend') {
                    sh """
                        echo "Building backend Docker image..."
                        docker build -t ${DOCKER_USERNAME}/bookstore-backend:${params.BACKEND_DOCKER_TAG} .
                    """
                }
                echo "Backend image built successfully"
            }
        }

        stage('Scan Docker Images') {
            steps {
                sh """
                    echo "Scanning Docker images for vulnerabilities..."
                    trivy image --format table ${DOCKER_USERNAME}/bookstore-frontend:${params.FRONTEND_DOCKER_TAG} || true
                    trivy image --format table ${DOCKER_USERNAME}/bookstore-backend:${params.BACKEND_DOCKER_TAG} || true
                """
                echo "Docker image scanning completed"
            }
        }

        stage('Push Images to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-token',
                    passwordVariable: 'DOCKER_PASSWORD',
                    usernameVariable: 'DOCKER_USER'
                )]) {
                    sh """
                        echo "Logging into DockerHub..."
                        docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}
                        
                        echo "Pushing frontend image..."
                        docker push ${DOCKER_USERNAME}/bookstore-frontend:${params.FRONTEND_DOCKER_TAG}
                        
                        echo "Pushing backend image..."
                        docker push ${DOCKER_USERNAME}/bookstore-backend:${params.BACKEND_DOCKER_TAG}
                    """
                }
                echo "Images pushed to DockerHub successfully"
            }
        }

        /* --------------------- GITOPS DEPLOYMENT --------------------- */
        stage('Verify Docker Tags') {
            steps {
                echo "Frontend Docker Tag: ${params.FRONTEND_DOCKER_TAG}"
                echo "Backend Docker Tag: ${params.BACKEND_DOCKER_TAG}"
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error "Docker tags cannot be empty!"
                    }
                }
            }
        }

        stage('Update Helm Values') {
            steps {
                script {
                    dir('helm-chart') {
                        sh """
                            echo "Updating backend image tag in Helm values..."
                            sed -i 's|backend:\\s*\\n\\s*image:\\s*\\n\\s*repository: ${DOCKER_USERNAME}/bookstore-backend\\n\\s*tag:.*|backend:\\n  image:\\n    repository: ${DOCKER_USERNAME}/bookstore-backend\\n    tag: ${params.BACKEND_DOCKER_TAG}|' values.yaml

                            echo "Updating frontend image tag in Helm values..."
                            sed -i 's|frontend:\\s*\\n\\s*image:\\s*\\n\\s*repository: ${DOCKER_USERNAME}/bookstore-frontend\\n\\s*tag:.*|frontend:\\n  image:\\n    repository: ${DOCKER_USERNAME}/bookstore-frontend\\n    tag: ${params.FRONTEND_DOCKER_TAG}|' values.yaml
                    """
                    }
                    echo "Helm values updated successfully"
                }
            }
        }

        stage('Commit and Push Changes') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'github-token', gitToolName: 'Default')]) {
                    sh """
                        git config user.email "jenkins@ci.com"
                        git config user.name "Jenkins GitOps"

                        git add kubernetes/*.yml
                        git commit -m "GitOps: Update image tags to frontend:${params.FRONTEND_DOCKER_TAG}, backend:${params.BACKEND_DOCKER_TAG}" || echo "No changes to commit"

                        git push ${GIT_REPO_URL} ${GIT_BRANCH}
                    """
                }
                echo "Changes pushed to GitHub successfully"
            }
        }
    }

    /* --------------------- POST ACTIONS --------------------- */
    post {
        always {
            echo "Pipeline execution completed"
            archiveArtifacts artifacts: '*.html,**/*.xml', allowEmptyArchive: true
        }

        success {
            echo "✅ Pipeline completed successfully!"
            echo "📦 Updated images:"
            echo "   Frontend: ${DOCKER_USERNAME}/bookstore-frontend:${params.FRONTEND_DOCKER_TAG}"
            echo "   Backend: ${DOCKER_USERNAME}/bookstore-backend:${params.BACKEND_DOCKER_TAG}"

            script {
                emailext(
                    subject: "✅ GitOps Deployment Success - BookStore App",
                    body: """
                        <h2>🚀 CI/CD Pipeline Successful</h2>
                        <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                        <p><strong>Build:</strong> ${env.BUILD_NUMBER}</p>
                        <p><strong>Status:</strong> ${currentBuild.result}</p>
                        
                        <h3>📦 Updated Images:</h3>
                        <ul>
                            <li>Frontend: ${DOCKER_USERNAME}/bookstore-frontend:${params.FRONTEND_DOCKER_TAG}</li>
                            <li>Backend: ${DOCKER_USERNAME}/bookstore-backend:${params.BACKEND_DOCKER_TAG}</li>
                        </ul>
                        
                        <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                        <p><em>ArgoCD will automatically sync these changes to the cluster.</em></p>
                    """,
                    to: 'atkaridarshan04@gmail.com',
                    mimeType: 'text/html'
                )
            }
        }

        failure {
            echo "❌ Pipeline failed!"
            script {
                emailext(
                    subject: "❌ CI/CD Pipeline Failed - BookStore App",
                    body: """
                        <h2>🚨 Pipeline Failed</h2>
                        <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                        <p><strong>Build:</strong> ${env.BUILD_NUMBER}</p>
                        <p><strong>Status:</strong> ${currentBuild.result}</p>
                        
                        <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                        <p>Please check the build logs for details.</p>
                    """,
                    to: 'atkaridarshan04@gmail.com',
                    mimeType: 'text/html'
                )
            }
        }

        unstable {
            echo "⚠️ Pipeline completed with warnings"
        }
    }
}
