package python

import (
    "universe.dagger.io/docker"
)

#Image: {
    // Python 3 minor version.
    pythonMinorVersion: string | *"10"

    docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "python:3.\(pythonMinorVersion)-slim-bullseye"
            },
            docker.#Run & {
                command: {
                    name:  "pip"
                    args:  ["install", "pytest", "coverage", "pipenv", "poetry"]
                }
            }
        ]
    }
}
