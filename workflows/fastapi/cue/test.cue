package main

import (
    "dagger.io/dagger"

    "trustacks.io/flake8"
    "trustacks.io/fastapi"
)

// Run unit tests and lint.
#Test: {
    // React source code.
    source: dagger.#FS

    // Lint source.
    lint: flake8.#Run & {
        "source": source
    }
    
    // Run Unit tests.
    fastapi.#Test & {
        "source": source
    }
}
