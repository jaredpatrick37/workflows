package fastapi

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"

    "universe.dagger.io/docker"

    "trustacks.io/python"
)

// Build the application container.
#Containerize: {
    // Image tag.
    tag: string

    // Python 3 minor version.
    pythonMinorVersion: string | *"10"

    // Python package name.
    packageName: string | *"app"

    // Docker build assets.
    assets: dagger.#FS

    // Project source..
    source: dagger.#FS

    // Container image.
    image: _container.output

    // Container filesystem.
    output: _export.output

    _container: docker.#Build & {
        _requirements: python.#Requirements & {
            "source": source
        }
        steps: [
            docker.#Pull & {
                source: "python:3.\(pythonMinorVersion)-slim-bullseye"
            },
            docker.#Copy & {
                "dest":     "/app"
                "contents": source
            },
            docker.#Copy & {
                "source":   "/requirements.txt"
                "dest":     "/tmp/requirements.txt"
                "contents": _requirements.output
            },
            docker.#Run & {
                command: {
                    name: "pip"
                    args: ["install", "-r", "/tmp/requirements.txt"]
                }
            },
            docker.#Set & {
                config: {
                    workdir: "/app"
                    cmd:     ["uvicorn", "--host", "0.0.0.0", "--port", "8080", "\(packageName).main:app"]
                }
            }
        ]
    }

    _export: core.#Export & {
        "tag":  tag
		input:  _container.output.rootfs
        config: _container.output.config
	}
}