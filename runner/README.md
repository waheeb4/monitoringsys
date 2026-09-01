# Local Jenkins runner

This setup runs Jenkins locally with the tools required by this repository's
pipeline:

- Docker CLI and Docker Compose v2, using the host Docker daemon;
- Node.js and Newman for the Postman sanity pack;
- `oc` and `kubectl` for an optional OpenShift deployment stage.

## Start Jenkins

From the repository root:

```bash
docker build --tag monitoring-jenkins runner

docker run --detach \
    --name monitoring-jenkins \
    --user 0:0 \
    --publish 8088:8080 \
    --volume jenkins_home:/var/jenkins_home \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$PWD:$PWD" \
    monitoring-jenkins
```

The `"$PWD:$PWD"` mount must be run from the repository root — it puts the CI
checkout at the identical absolute path inside Jenkins and on the host Docker
daemon, which the pipeline relies on for Compose file secrets.

Open <http://localhost:8088>. Retrieve the one-time administrator password:

```bash
docker exec monitoring-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Create a Pipeline job that uses this repository's `Jenkinsfile`.

Before running the pipeline, set `CI_WORKSPACE_ROOT` as a Jenkins global
environment variable (Manage Jenkins > System > Global properties) to this
repository's absolute checkout path on the host. The `Jenkinsfile` uses it to
build a `customWorkspace` that lines up with the `"$PWD:$PWD"` bind mount
above.

## Important security note

The Docker socket mount lets pipeline jobs build and run Docker containers on
the host. The Jenkins container runs as root only so it can access that socket.
Use this setup only for this local development environment; do not expose it as
a shared or internet-facing Jenkins instance.

## Verify the toolchain

In a Jenkins Pipeline shell step, run:

```bash
docker version
docker compose version
newman --version
oc version --client
```

OpenShift deployment remains intentionally unconfigured. Store a project-scoped
OpenShift deployer credential in Jenkins before adding an `oc login` and
`oc set image` deployment stage.
