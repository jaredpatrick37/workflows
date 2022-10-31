package poetry

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Run the eslint utility.
#Install: {
    // The project source code.
    source: dagger.#FS

    // Output is the source with installed poetry dependencies
    output: _container.export.directories."/output"

    // Command return code.
    code: _container.export.files."/code"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        if [ -f poetry.lock ]; then
            pip install $(poetry run pip freeze)
        elif [ -f Pipfile.lock ]; then
            pip install $(pipenv run pip freeze)
        elif [ -f requirements.txt ]; then
            pip install -r requirements.txt
        fi
        cp -R /src /output
        echo $$ > /code
        """#

        export: {
            directories: "/output": dagger.#FS
            files:       "/code": string
        }

        mounts: {
            "src": {
                dest:     "/src"
                contents: source
            }
        }
    }
}

#Test: {
    // The project source code.
    source: dagger.#FS

    // Command return code.
    code: _container.export.files."/code"

    _install: #Install & {
        "source": source
    }

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        poetry config virtualenvs.in-project true
        poetry run coverage run -m py.test -v --color=yes
        poetry run coverage report -m
        echo $$ > /code
        """#

        export: files: "/code": string

        mounts: {
            "src": {
                dest:     "/src"
                contents: _install.output
            }
        }
    }
}
