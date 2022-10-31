package fastapi

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"

    "trustacks.io/python"
)

#Version: {
    // The project source code.
    source: dagger.#FS

    // Commit version id.
    output: _container.export.files."/output"

    // Command return code.
    code: _container.export.files."/code"

    _install: python.#Install & {
        "source": source
    }

    _container: bash.#Run & {
        _image:  #Image
        input:   _image.output
        workdir: "/src"

        script: contents: #"""
        
        echo $$ > /code
        """#

        export: files: {
            "/code":   string
            "/output": string
        }

        mounts: {
            "src": {
                dest:     "/src"
                contents: source
            }
        }
    }
}
