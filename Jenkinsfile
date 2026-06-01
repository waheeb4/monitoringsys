pipeline { // Declares this as a Jenkins declarative pipeline
    agent any // Run on any available Jenkins agent/node

    environment { // Defines variables available to all stages
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials') // Loads Docker Hub username & password from Jenkins credentials store — auto-creates DOCKER_HUB_CREDENTIALS_USR and DOCKER_HUB_CREDENTIALS_PSW
        DOCKER_HUB_USERNAME = 'waheeb4' // Your Docker Hub account name used to tag and push images
        IMAGE_VERSION = "v1.${BUILD_NUMBER}" // Unique version tag per build — BUILD_NUMBER is auto-incremented by Jenkins (e.g. v1.18, v1.19)
    }

    stages { // Container for all sequential stages

        stage('Checkout') { // Stage 1: get all source code Jenkins needs
            steps {
                echo 'Pulling pipeline config from GitHub...' // Prints message to Jenkins console log
                checkout scm // Clones the repo where THIS Jenkinsfile lives — gives Jenkins access to docker-compose.hub.yml

                echo 'Detecting and cloning most recently updated branches...' // Prints message to Jenkins console log
                sshagent(['github-ssh']) { // Loads the SSH private key from Jenkins credential 'github-ssh' into an ssh-agent for this block — git picks it up automatically (requires the SSH Agent plugin)

                    // ── BACKEND ──────────────────────────────────────────────
                    sh '''
                        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
                        # github.com is not in the container's known_hosts on a fresh build — accept-new trusts it on first connect so the SSH clone doesn't fail host-key verification

                        git clone --bare git@github.com:nabil0412/IoT-Monitoring-System-backend.git /tmp/backend-temp
                        # Clone only git metadata of backend repo (no source files) — bare is fast and lightweight

                        LATEST=$(git -C /tmp/backend-temp for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/ | head -1)
                        # List all backend branches sorted by commit date newest first — head -1 picks the most recently updated one

                        echo "Backend — most recently updated branch: $LATEST"
                        # Print the detected branch name so it appears in Jenkins logs for visibility

                        rm -rf /tmp/backend-temp
                        # Delete the temporary bare clone — no longer needed

                        rm -rf backend-repo && git clone -b $LATEST git@github.com:nabil0412/IoT-Monitoring-System-backend.git backend-repo
                        # Delete any old backend-repo folder, then do the real full clone using the detected branch
                    '''

                    // ── FRONTEND ─────────────────────────────────────────────
                    sh '''
                        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
                        # github.com is not in the container's known_hosts on a fresh build — accept-new trusts it on first connect so the SSH clone doesn't fail host-key verification

                        git clone --bare git@github.com:nabil0412/IoT-Monitoring-System-frontend.git /tmp/frontend-temp
                        # Clone only git metadata of frontend repo (no source files) — bare is fast and lightweight

                        LATEST=$(git -C /tmp/frontend-temp for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/ | head -1)
                        # List all frontend branches sorted by commit date newest first — head -1 picks the most recently updated one

                        echo "Frontend — most recently updated branch: $LATEST"
                        # Print the detected branch name so it appears in Jenkins logs for visibility

                        rm -rf /tmp/frontend-temp
                        # Delete the temporary bare clone — no longer needed

                        rm -rf frontend-repo && git clone -b $LATEST git@github.com:nabil0412/IoT-Monitoring-System-frontend.git frontend-repo
                        # Delete any old frontend-repo folder, then do the real full clone using the detected branch
                    '''
                }
            }
        }

        stage('Build Images') { // Stage 2: build the 3 Docker images from cloned source code
            steps {
                echo 'Building Docker images...' // Prints message to Jenkins console log
                sh "docker build -f backend-repo/backend.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-backend:${IMAGE_VERSION} ./backend-repo" // Builds Spring Boot backend image — uses backend.Dockerfile, tags as jaidazeidan/iot-backend:v1.X, build context is backend-repo/
                sh "docker build -f backend-repo/database.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-database:${IMAGE_VERSION} ./backend-repo" // Builds MySQL image — schema.sql is baked in so tables are pre-created on first start
                sh "docker build -f frontend-repo/frontend.Dockerfile -t ${DOCKER_HUB_USERNAME}/iot-frontend:${IMAGE_VERSION} ./frontend-repo" // Builds Angular + nginx frontend image — build context is frontend-repo/
            }
        }

        stage('Login to Docker Hub') { // Stage 3: authenticate with Docker Hub before pushing
            steps {
                echo 'Logging into Docker Hub...' // Prints message to Jenkins console log
                sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin" // Pipes password via stdin instead of typing as argument — safer, won't appear in process logs
            }
        }

        stage('Push Images') { // Stage 4: upload all 3 built images to Docker Hub
            steps {
                echo 'Pushing images to Docker Hub...' // Prints message to Jenkins console log
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-backend:${IMAGE_VERSION}" // Pushes jaidazeidan/iot-backend:v1.X to Docker Hub
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-database:${IMAGE_VERSION}" // Pushes jaidazeidan/iot-database:v1.X to Docker Hub
                sh "docker push ${DOCKER_HUB_USERNAME}/iot-frontend:${IMAGE_VERSION}" // Pushes jaidazeidan/iot-frontend:v1.X to Docker Hub
            }
        }

        stage('Deploy') { // Stage 5: pull pushed images and start all 3 containers
            steps {
                echo 'Deploying application...' // Prints message to Jenkins console log
                sh "IMAGE_VERSION=${IMAGE_VERSION} docker-compose -f docker-compose.hub.yml up -d" // Passes IMAGE_VERSION into docker-compose so it knows which tags to pull — -f uses our compose file — up -d starts containers in background
            }
        }
    }

    post { // Runs after all stages finish regardless of outcome
        success {
            echo 'Pipeline completed successfully!' // Printed if every stage passed
        }
        failure {
            echo 'Pipeline failed. Check the logs above.' // Printed if any stage failed
        }
    }
}
