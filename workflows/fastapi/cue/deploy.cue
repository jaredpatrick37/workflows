package main

import (
    "dagger.io/dagger"

    "trustacks.io/argocd"
)

// Deploy the application.
#Deploy: {
    // Input variables.
    vars: [name=string]: string

    // Input secrets.
    secrets: [name=string]: dagger.#Secret

    // The build version.
    version: string

    // Application deployment target.
    deployTarget: string

    k8s: {
        if deployTarget == "kubernetes" {
            argocd.#Create & {
                project:    vars."project"
                server:     vars."argo-cd.server"
                repo:       vars."gitRemote"
                revision:   "_ts-build"
                username:   "trustacks"
                password:   secrets."argo-cd.password"
                privateKey: secrets."gitPrivateKey"
                overlay:    "staging"
                insecure:   "true"
            }
        }
    }
}