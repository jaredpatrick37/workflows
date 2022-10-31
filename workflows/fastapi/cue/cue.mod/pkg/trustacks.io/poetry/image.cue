package poetry

import (
    "universe.dagger.io/docker"
)

_#DefaultVersion: "8.6"

#Image: {
    version: *_#DefaultVersion | string

    docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "fedora"
            },
            docker.#Run & {
                command: {
                    name: "dnf"
                    args: ["install", "-y", "gcc", "libpq-devel", "python3-pip"]
                }
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