pipeline {
    agent {
        node {
            label 'built-in'
            // Must resolve to the identical absolute path on both Jenkins and
            // the host Docker daemon, so it lives under CI_WORKSPACE_ROOT
            // rather than a path hardcoded here. Set CI_WORKSPACE_ROOT as a
            // Jenkins global environment variable (Manage Jenkins > System)
            // to this repo's absolute checkout path on the host. Do not point
            // this at the root working tree; it is an ignored, dedicated CI
            // checkout.
            customWorkspace "${CI_WORKSPACE_ROOT}/runner/jenkins-workspace/monitoring-system"
        }
    }

    environment {
        DOCKER_HUB_USERNAME = 'waheeb4'
        IMAGE_VERSION = "v1.${BUILD_NUMBER}"
        OPENSHIFT_NAMESPACE = 'waheeb4-dev'
        COMPOSE_PROJECT = 'iot-monitoring'
    }

    stages {
        stage('Build Images') {
            steps {
                sh 'docker compose -p "$COMPOSE_PROJECT" build'
            }
        }

        stage('Prepare CI Secret') {
            steps {
                withCredentials([string(credentialsId: 'mysql-root-password', variable: 'MYSQL_ROOT_PASSWORD')]) {
                    sh '''
                        set -eu
                        mkdir -p secrets
                        install -o 1001 -g 1001 -m 0400 \
                            /dev/null secrets/mysql_root_password.txt
                        printf '%s' "$MYSQL_ROOT_PASSWORD" > secrets/mysql_root_password.txt
                    '''
                }
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

                    newman run "postman/Sanity-Pack/Sanity Check.postman_collection.json" \
                        --environment "postman/Sanity-Pack/IoT monitoring system - dev.postman_environment.json" \
                        --env-var baseUrl=http://backend:8080
                '''
            }
        }

        stage('Publish Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_TOKEN')]) {
                    sh '''
                        set +x
                        printf '%s' "$DOCKER_HUB_TOKEN" | docker login --username "$DOCKER_HUB_USER" --password-stdin

                        for service in database-service backend-service frontend-service; do
                            local_image="$service:dev"
                            remote_image="$DOCKER_HUB_USERNAME/$service:$IMAGE_VERSION"
                            docker image tag "$local_image" "$remote_image"
                            docker push "$remote_image"
                        done
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
                docker logout >/dev/null 2>&1 || true
                oc logout >/dev/null 2>&1 || true
                rm -f secrets/mysql_root_password.txt
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
