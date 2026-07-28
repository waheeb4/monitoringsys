pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = 'waheeb4'
        IMAGE_VERSION = "v1.${BUILD_NUMBER}"
        OPENSHIFT_NAMESPACE = 'waheeb4-dev'
        COMPOSE_PROJECT = 'iot-monitoring'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                // Use the exact backend/frontend commits recorded by this repository.
                // HTTPS avoids requiring an extra GitHub SSH credential for public submodules.
                sh '''
                    git config submodule.IoT-Monitoring-System-backend.url https://github.com/nabil0412/IoT-Monitoring-System-backend.git
                    git config submodule.IoT-Monitoring-System-frontend.url https://github.com/nabil0412/IoT-Monitoring-System-frontend.git
                    git submodule update --init --recursive \
                        IoT-Monitoring-System-backend \
                        IoT-Monitoring-System-frontend
                '''
            }
        }

        stage('Build Images') {
            steps {
                sh 'docker compose -p "$COMPOSE_PROJECT" build'
            }
        }

        stage('Sanity Validation') {
            steps {
                sh '''
                    set -eu
                    docker compose -p "$COMPOSE_PROJECT" up --detach --wait --wait-timeout 180 database-service backend

                    # Newman runs inside Jenkins, so attach Jenkins to the same Docker
                    # network and use the backend service name rather than localhost.
                    docker network connect "${COMPOSE_PROJECT}_backend-net" monitoring-jenkins
                    trap 'docker network disconnect "${COMPOSE_PROJECT}_backend-net" monitoring-jenkins >/dev/null 2>&1 || true' EXIT

                    newman run "Sanity-Pack/Sanity Check.postman_collection.json" \
                        --environment "Sanity-Pack/IoT monitoring system - dev.postman_environment.json" \
                        --env-var baseUrl=http://backend:8080
                '''
            }
        }

        stage('Tag Images') {
            steps {
                sh '''
                    docker image tag database-service:dev "$DOCKER_HUB_USERNAME/database-service:$IMAGE_VERSION"
                    docker image tag backend-service:dev "$DOCKER_HUB_USERNAME/backend-service:$IMAGE_VERSION"
                    docker image tag frontend-service:dev "$DOCKER_HUB_USERNAME/frontend-service:$IMAGE_VERSION"
                '''
            }
        }

        stage('Push Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_TOKEN')]) {
                    sh '''
                        set +x
                        printf '%s' "$DOCKER_HUB_TOKEN" | docker login --username "$DOCKER_HUB_USER" --password-stdin
                        docker push "$DOCKER_HUB_USERNAME/database-service:$IMAGE_VERSION"
                        docker push "$DOCKER_HUB_USERNAME/backend-service:$IMAGE_VERSION"
                        docker push "$DOCKER_HUB_USERNAME/frontend-service:$IMAGE_VERSION"
                    '''
                }
            }
        }

        stage('Deploy to OpenShift') {
            steps {
                withCredentials([string(credentialsId: 'openshift', variable: 'OPENSHIFT_TOKEN')]) {
                    sh '''
                        set +x
                        : "${OPENSHIFT_SERVER:?Set OPENSHIFT_SERVER in Jenkins global environment variables.}"
                        oc login --token="$OPENSHIFT_TOKEN" --server="$OPENSHIFT_SERVER"

                        oc set image deployment/database-deployment \
                            database="$DOCKER_HUB_USERNAME/database-service:$IMAGE_VERSION" \
                            --namespace="$OPENSHIFT_NAMESPACE"
                        oc scale deployment/database-deployment --replicas=1 --namespace="$OPENSHIFT_NAMESPACE"
                        oc rollout status deployment/database-deployment --namespace="$OPENSHIFT_NAMESPACE" --timeout=180s

                        oc set image deployment/backend-deployment \
                            backend="$DOCKER_HUB_USERNAME/backend-service:$IMAGE_VERSION" \
                            --namespace="$OPENSHIFT_NAMESPACE"
                        oc scale deployment/backend-deployment --replicas=1 --namespace="$OPENSHIFT_NAMESPACE"
                        oc rollout status deployment/backend-deployment --namespace="$OPENSHIFT_NAMESPACE" --timeout=180s

                        oc set image deployment/frontend-deployment \
                            frontend="$DOCKER_HUB_USERNAME/frontend-service:$IMAGE_VERSION" \
                            --namespace="$OPENSHIFT_NAMESPACE"
                        oc scale deployment/frontend-deployment --replicas=1 --namespace="$OPENSHIFT_NAMESPACE"
                        oc rollout status deployment/frontend-deployment --namespace="$OPENSHIFT_NAMESPACE" --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker network disconnect "${COMPOSE_PROJECT}_backend-net" monitoring-jenkins >/dev/null 2>&1 || true
                docker compose -p "$COMPOSE_PROJECT" down --volumes --remove-orphans || true
            '''
        }
        success {
            echo "Pipeline completed successfully. Deployed image tag ${IMAGE_VERSION}."
        }
        failure {
            echo 'Pipeline failed. The local test stack was cleaned up; OpenShift is unchanged unless deployment had already begun.'
        }
    }
}
