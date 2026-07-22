pipeline { 
    agent any 

    environment { 
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials') 
        DOCKER_HUB_USERNAME = 'waheeb4' 
        IMAGE_VERSION = "v1.${BUILD_NUMBER}" 
    }

    stages { 

        stage('Checkout') { 
            steps {
                echo 'Pulling pipeline config from GitHub...' 
                checkout scm 

                echo 'Detecting and cloning most recently updated branches...' 
                sshagent(['github-ssh']) { 

                    // ── BACKEND ──────────────────────────────────────────────
                    sh '''
                        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
                        git clone --bare git@github.com:nabil0412/IoT-Monitoring-System-backend.git /tmp/backend-temp
                        LATEST=$(git -C /tmp/backend-temp for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/ | head -1)
                        echo "Backend — most recently updated branch: $LATEST"
                        rm -rf /tmp/backend-temp
                        rm -rf backend-repo && git clone -b $LATEST git@github.com:nabil0412/IoT-Monitoring-System-backend.git backend-repo
                    '''

                    // ── FRONTEND ─────────────────────────────────────────────
                    sh '''
                        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
                        git clone --bare git@github.com:nabil0412/IoT-Monitoring-System-frontend.git /tmp/frontend-temp
                        LATEST=$(git -C /tmp/frontend-temp for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/ | head -1)
                        echo "Frontend — most recently updated branch: $LATEST"
                        rm -rf /tmp/frontend-temp
                        rm -rf frontend-repo && git clone -b $LATEST git@github.com:nabil0412/IoT-Monitoring-System-frontend.git frontend-repo
                    '''
                }
            }
        }

        // ── NEW STAGE: SANITY VALIDATION ─────────────────────────────────────────
        stage('Sanity Validation') { 
            steps {
                echo 'Executing Postman Sanity Pack via Newman...' 
                
                // Install Newman globally on the Jenkins runner (requires Node.js on the agent)
                sh 'npm install -g newman'
                
                // Run the Postman collection against the environment variables.
                // Note: The quotes handle the spaces in your file names. 
                // If any test fails, Newman returns an error code (exit 1), automatically failing the pipeline here.
                sh '''
                    newman run "Sanity-Pack/Sanity Check.postman_collection.json" \
                    -e "Sanity-Pack/IoT monitoring system - dev.postman_environment.json"
                '''
            }
        }
        // ─────────────────────────────────────────────────────────────────────────

        stage('Build Images') { 
            steps {
                echo 'Building Docker images...' 
                sh "docker build -f backend-repo/backend.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-backend:${IMAGE_VERSION} ./backend-repo" 
                sh "docker build -f backend-repo/database.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-database:${IMAGE_VERSION} ./backend-repo" 
                sh "docker build -f frontend-repo/frontend.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-frontend:${IMAGE_VERSION} ./frontend-repo" 
            }
        }

        stage('Login to Docker Hub') { 
            steps {
                echo 'Logging into Docker Hub...' 
                sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin" 
            }
        }

        stage('Push Images') { 
            steps {
                echo 'Pushing images to Docker Hub...' 
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-backend:${IMAGE_VERSION}" 
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-database:${IMAGE_VERSION}" 
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-frontend:${IMAGE_VERSION}" 
            }
        }

        stage('Deploy') { 
            steps {
                echo 'Deploying application...' 
                sh "IMAGE_VERSION=${IMAGE_VERSION} docker-compose -p iot-monitoring -f docker-compose.hub.yml up -d" 
            }
        }
    }

    post { 
        success {
            echo 'Pipeline completed successfully!' 
        }
        failure {
            echo 'Pipeline failed. Check the logs above.' 
        }
    }
}