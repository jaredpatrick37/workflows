package flake8

import (
    "universe.dagger.io/docker"
)

_#DefaultVersion: "8.6"

#Image: {
    version: *_#DefaultVersion | string

    docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "registry.access.redhat.com/ubi8/ubi-minimal:\(version)"
            },
            docker.#Run & {
                command: {
                    name: "microdnf"
                    args: ["install", "bash", "git", "python39"]
                }
            },
            docker.#Run & {
                command: {
                    name:  "pip3"
                    args:  ["install", "flake8"]
                }
            }
        ]
    }
}