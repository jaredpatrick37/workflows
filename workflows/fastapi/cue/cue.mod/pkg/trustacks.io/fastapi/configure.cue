package fastapi

import (
    "dagger.io/dagger"
    
    "universe.dagger.io/bash"
)

// Configure the source before executing actions.
#Configure: {
    // The project source code.
    source: dagger.#FS

    // Remote git repository.
    remote: string

    // source private key.
    privateKey: dagger.#Secret

    // Configuration exit code.
	code: _container.export.files."/code"
    
    // Build version number.
    build: _container.export.files."/build"

    // The modified source.
    output: _container.export.directories."/_src"
 
    _container: bash.#Run & {
        _image:  #Image
        input:   _image.output
        workdir: "/src"
        always:  true

        script: contents: #"""
        if [ -f .ignore-configure ]; then
            exit 0
        fi
        touch .ignore-configure

        mkdir ~/.ssh
        echo -e "$PRIVATE_KEY" > ~/.ssh/id_rsa
        
        chmod 600 ~/.ssh/id_rsa
        git remote set-url origin $REMOTE
        GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' git fetch

        git checkout -b _ts-build
        git pull origin _ts-build || true
        mkdir -p .trustacks
        
        cat > .trustacks/.build.ini <<EOF
        commit=$(git log --pretty=oneline -1)
        EOF

        git config user.name "trustacks"
        git config user.email "ci@trustacks.io"
        git add .trustacks
        git commit -m "ci: add .build.ini"
        git rev-parse --short HEAD | tr -d '\n' > /build
        
        echo $$ > /code
        cp -R /src /_src
        """#

        export: {
            directories: "/_src": dagger.#FS
            files: {
                "/build": string
                "/code":  string
            }
        }
        
        env: {
            PRIVATE_KEY: privateKey
            REMOTE:      remote
        }

        mounts: {
            "src": {
                dest:     "/src"
                contents: source
            }
        }
    }
}
