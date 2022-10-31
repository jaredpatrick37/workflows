package fastapi

import (
    "encoding/yaml"
    "strings"

    "dagger.io/dagger"
    
    "universe.dagger.io/bash"
)

// Prepare the kustomize assets for deployment. 
#Kustomize: {
    // Source input.
    input: dagger.#FS

    // Build assets
    assets: dagger.#FS

    // Helm template values.
    values: _

    // registrySecret is used to the pull the application image.
    registrySecret: string

    // Password for the database.
    databasePassword: string

    // Liquibase changelog.
    databaseChangelog: string | *null

    // Other actions required to run before this one.
    requires: [...string]
    
    // Command return code.
	code: _container.export.files."/code"

    // Tagged source.
    output: _container.export.directories."/output"
    
    _container: bash.#Run & {
        _image:  #Image
        "input": _image.output
        workdir: "/src"
        always: true

        script: contents: #"""
        # render helm templates
        mkdir /tmp/helm
        cp -R /assets/templates /tmp/helm/templates
        
        cat > /tmp/helm/Chart.yaml <<EOF
        apiVersion: v1
        name: templates
        version: 0
        EOF

        echo "$VALUES" > /tmp/values.yaml
        helm template -f /tmp/values.yaml /tmp/helm --output-dir /tmp/output
        cp /tmp/output/templates/templates/* /assets/kustomize/base

        for template in $(ls /tmp/output/templates/templates/); do
            echo "- $template" >> /assets/kustomize/base/kustomization.yaml
        done

        # write registry pull secret
        echo "$REGISTRY_SECRET" > /assets/kustomize/base/registry-secret.yaml
        
        # write database password secret
        echo "$DATABASE_PASSWORD" > /assets/kustomize/base/database-password.yaml

        # write the database changelog configmap
        if [ ! -z $(echo $DATABASE_CHANGELOG | awk '/apiVersion/ {print $1}' ) ]; then 
            echo "$DATABASE_CHANGELOG" > /assets/kustomize/base/database-changelog.yaml
            echo "- database-changelog.yaml" >> /assets/kustomize/base/kustomization.yaml
        fi

        mkdir -p /src/.trustacks
        cp -R /assets/kustomize /src/.trustacks/kustomize
        cp -R /src /output
        
        echo $$ > /code
        """#

        env: {
            REQUIRES:          strings.Join(requires, "_")
            REGISTRY_SECRET:   registrySecret
            DATABASE_PASSWORD: databasePassword
            VALUES:            yaml.Marshal(values)
            if databaseChangelog != null {
                DATABASE_CHANGELOG: databaseChangelog
            }
        }

        export: {
            directories: "/output": dagger.#FS
            files:       "/code": string
        }

        mounts: {
            "src": {
                dest:     "/src"
                contents: input
            }
            "assets": {
                dest:     "/assets"
                contents: assets
            }
        }
    }
}