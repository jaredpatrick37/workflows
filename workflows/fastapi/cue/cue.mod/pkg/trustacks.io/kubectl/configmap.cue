package kubectl

import (
    "strings"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Create a kubernetes configmape.
#ConfigMap: {
    // Configmap name.
    name: string

    // Resource namespace.
    namespace: string

    // Literal secret value key pairs
    fromLiterals: [key=string]: string

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
        mkdir /tmp/values
        for key in $(env | grep CONFIGMAP_DATA_); do
            value=$(echo $key | cut -d "=" -f1)
            echo "${!value}" > /tmp/values/$(echo $key | cut -d "_" -f3 | cut -d "=" -f1)
        done
        kubectl create configmap $NAME \
            --dry-run=$DRY_RUN \
            --from-file=/tmp/values \
            -o yaml \
            -n $NAMESPACE \
        | tee /output/configmap.yaml > /dev/null
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
            for key, value in fromLiterals {
                "CONFIGMAP_DATA_\(key)": value
            }
        }
    }
}
