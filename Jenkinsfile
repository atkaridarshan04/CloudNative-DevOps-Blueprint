pipeline {
    agent any

    environment {
        SONAR_HOME      = tool "sonar"
        AWS_REGION      = "us-west-2" 
        AWS_ACCOUNT_ID  = credentials('aws-account-id') // AWS account ID in Jenkins credentials
        ECR_REPO_FRONT  = "bookstore-frontend"
        ECR_REPO_BACK   = "bookstore-backend"
        GIT_REPO_URL    = "https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint.git"
        GIT_BRANCH      = "prod"
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
                        docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONT}:${params.FRONTEND_DOCKER_TAG} .
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
                        docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACK}:${params.BACKEND_DOCKER_TAG} .
                    """
                }
                echo "Backend image built successfully"
            }
        }

        stage('Scan Docker Images') {
            steps {
                sh """
                    echo "Scanning Docker images for vulnerabilities..."
                    trivy image --format table ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONT}:${params.FRONTEND_DOCKER_TAG} || true
                    trivy image --format table ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACK}:${params.BACKEND_DOCKER_TAG} || true
                """
                echo "Docker image scanning completed"
            }
        }

        stage('Push Images to ECR') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-access-key') {
                    sh """
                        echo "Logging into AWS ECR..."
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        echo "Pushing frontend image..."
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONT}:${params.FRONTEND_DOCKER_TAG}

                        echo "Pushing backend image..."
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACK}:${params.BACKEND_DOCKER_TAG}
                    """
                }
                echo "Images pushed to AWS ECR successfully"
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
                            echo "Updating backend image in Helm values..."
                            yq e -i '.backend.image.repo = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACK}"' values.yaml
                            yq e -i '.backend.image.tag = "${params.BACKEND_DOCKER_TAG}"' values.yaml

                            echo "Updating frontend image in Helm values..."
                            yq e -i '.frontend.image.repo = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONT}"' values.yaml
                            yq e -i '.frontend.image.tag = "${params.FRONTEND_DOCKER_TAG}"' values.yaml
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

                        git add helm-chart/values.yaml
                        git commit -m "GitOps: Update image tags to frontend:${params.FRONTEND_DOCKER_TAG}, backend:${params.BACKEND_DOCKER_TAG}" || echo "No changes to commit"

                        git push ${GIT_REPO_URL} ${GIT_BRANCH}
                    """
                }
                echo "Changes pushed to GitHub successfully"
            }
        }
    }

    post {
        always {
            echo "Pipeline execution completed"
            archiveArtifacts artifacts: '*.html,**/*.xml', allowEmptyArchive: true
        }
    }
}
