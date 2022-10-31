package flake8

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Run the eslint utility.
#Run: {
    // The project source code.
    source: dagger.#FS

    // Project name, used for cache scoping
    project: string | *"default"

    // Use this config if an eslintrc is not present in the source.
    defaultConfig: _ | *{}

    // Command return code.
    code: _container.export.files."/code"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        flake8 --color=always --exclude tests
        echo $$ > /code
        """#

        export: files: "/code": string

        mounts: {
            "src": {
                dest:     "/src"
                contents: source
            }
        }
    }
}
