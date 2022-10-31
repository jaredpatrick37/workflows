package python

import (
    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

#Requirements: {
    // The project source code.
    source: dagger.#FS

    // Requirements.txt if found or generated.
    output: _container.export.directories."/output"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
        mkdir /output

        if [ -f poetry.lock ]; then
            poetry export > /output/requirements.txt
        elif [ -f Pipfile.lock ]; then
            pipenv requirements >  /output/requirements.txt
        fi

        if [ -f requirements.txt ]; then
            pip install -r /output/requirements.txt
        fi
        """#

        export: directories: "/output": dagger.#FS

        mounts: "src": {
            dest:     "/src"
            contents: source
        }
    }
}

// Install python packages.
#Install: {
    // The project source code.
    source: dagger.#FS

    // Output is the source with installed dependencies.
    output: _container.output

    _container: bash.#Run & {
        _image:        #Image
        input:         *_image.output | docker.#Image

        script: contents: #"""
        if [ -f /tmp/requirements.txt ]; then
            pip install -r /tmp/requirements.txt
        fi
        """#

        _requirements: #Requirements & {
            "source": source
        }

        mounts: {
            "tmp": {
                dest:     "/tmp"
                contents: _requirements.output
            }
        }
    }
}
