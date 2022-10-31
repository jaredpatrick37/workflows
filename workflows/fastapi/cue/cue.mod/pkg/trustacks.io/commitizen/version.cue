package commitizen

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Bump to the next semantic release version without committing to 
// the remote git repository.
#Version: {
    // Project source code.
    source: dagger.#FS

    // // Remote git repository.
    // remote: string

    // // source private key.
    // privateKey: dagger.#Secret

    // Command return code.
    code: _container.export.files."/code"

    // // TruStacks trunk branch source.
    // output: _container.export.directories."/_src"

    // Version bumped source.
    version: _container.export.files."/version"
    
    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"
        always:  true

        script: contents: #"""
        git tag -l
        if [ ! -z $(git tag -l | awk '{print $1}') ]; then
            latest_tag=$(git describe --tag `git rev-list --tags --max-count=1` || true)
            git checkout tags/$latest_tag -- CHANGELOG.md
            git checkout tags/$latest_tag -- .cz.json
        else
            echo '{"commitizen": {"version": "0.0.0"}}' > .cz.json 
        fi
        touch /version
        bump=$(cz bump --yes --dry-run)
        echo $bump
        if [ -z $(echo "$bump" | awk '/No new commits found/ {print $1}') ]; then
            echo $bump | awk '/tag to create:/ {print $5}' | tr -d '\n'  > /version
        fi
        echo $$ > /code
        """#

        "mounts": src: {
            dest:     "/src"
            contents: source
        }
        
        // env: {
        //     PRIVATE_KEY: privateKey
        //     REMOTE:      remote
        // }
        
        export: {
            // directories: "/_src": dagger.#FS
            files: {
                "/code":    string
                "/version": string
            }
        }
    }
}