package pytest

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Run the eslint utility.
#Run: {
    // The project source code.
    source: dagger.#FS

    // Virtual environmen path
    venv: string | *".venv"

    // Command return code.
    code: _container.export.files."/code"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        source $VENV/bin/activate
        py.test
        echo $$ > /code
        """#

        env: VENV: venv

        export: files: "/code": string

        mounts: {
            "src": {
                dest:     "/src"
                contents: source
            }
        }
    }
}
