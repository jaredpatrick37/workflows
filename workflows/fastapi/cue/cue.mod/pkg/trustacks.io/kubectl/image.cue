package kubectl

import (
    "universe.dagger.io/docker"
)

#Image: {
    docker.#Pull & {
        source: "quay.io/trustacks/cuelib-kubectl"
    }
}