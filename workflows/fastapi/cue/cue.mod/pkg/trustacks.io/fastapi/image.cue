package fastapi

import (
    "universe.dagger.io/docker"
)

#Image: {
    docker.#Pull & {
        source: "quay.io/trustacks/cuelib-fastapi"
    }
}