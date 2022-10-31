package fastapi

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"

    "trustacks.io/python"
)

#Test: {
    // The project source code.
    source: dagger.#FS

    // Command return code.
    code: _container.export.files."/code"

    _install: python.#Install & {
        "source": source
    }

    _container: bash.#Run & {
        input:   _install.output
        workdir: "/src"

        script: contents: #"""
        python -m coverage run -m py.test -v --color=yes
        python -m coverage report -m
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
