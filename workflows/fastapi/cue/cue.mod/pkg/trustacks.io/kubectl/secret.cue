package kubectl

import (
    "strings"

    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

#GenericSecret: {
    // Secret name.
    name: string

    // Secret namespace.
    namespace: string

    // Literal secret value key pairs
    literals: [key=string]: dagger.#Secret
    
    // Run the command in dry-run mode.
    dryRun: string | *"none"

    // Other actions required to run before this one.
    requires: [...string]

    // command exit code.
	code: _container.export.files."/code"

    // Kubernetes docker registry secret.
    output: _container.export.directories."/output"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        mkdir /output
        mkdir -p /tmp/values
        for literal in $(env | grep SECRET_LITERAL_); do 
            echo $(echo $literal | cut -d "=" -f2) > /tmp/values/$(echo $literal | cut -d "_" -f3 | cut -d "=" -f1)
        done
        kubectl create secret generic $NAME \
            --dry-run=$DRY_RUN \
            --from-file=/tmp/values \
            -o yaml \
            -n $NAMESPACE \
        | tee /output/secret.yaml > /dev/null
        echo $$ > /code
        """#

        export: {
            directories: "/output": _
            files:       "/code": string
        }

        env: {
            NAME:      name
            NAMESPACE: namespace
            DRY_RUN:   dryRun
            REQUIRES:  strings.Join(requires, "_")
            for key, value in literals {
                "SECRET_LITERAL_\(key)": value
            }
        }
    }
}

// Create a kubernetes container registry secret.
#DockerRegistrySecret: {
    // Secret name.
    name: string

    // Secret namespace.
    namespace: string

    // Container registry server.
    server: string

    // Container registry username.
    username: string

    // Container registry password.
    password: dagger.#Secret

    // Run the command in dry-run mode.
    dryRun: string | *"none"

    // Other actions required to run before this one.
    requires: [...string]

    // command exit code.
	code: _container.export.files."/code"

    // Kubernetes docker registry secret.
    output: _container.export.directories."/output"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        mkdir /output
        kubectl create secret docker-registry $NAME \
            --dry-run=$DRY_RUN \
            --docker-server=$SERVER \
            --docker-username=$USERNAME \
            --docker-password=$PASSWORD \
            -o yaml \
            -n $NAMESPACE \
        | tee /output/secret.yaml > /dev/null
        echo $$ > /code
        """#

        export: {
            directories: "/output": _
            files:       "/code": string
        }

        env: {
            DRY_RUN:   dryRun
            NAME:      name
            NAMESPACE: namespace
            SERVER:    server
            USERNAME:  username
            PASSWORD:  password
            REQUIRES:  strings.Join(requires, "_")
        }
    }
}
