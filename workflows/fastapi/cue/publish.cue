package main

import (
    "dagger.io/dagger"
    "dagger.io/dagger/core"

    // "trustacks.io/commitizen"
    "trustacks.io/kubectl"
    "trustacks.io/sops"
    "trustacks.io/fastapi"
)

#Publish: {
    // React source code.
    source: dagger.#FS
    
    // Build assets.
    assets: dagger.#FS

    // Input variables.
    vars: [name=string]: string

    // Input secrets.
    secrets: [name=string]: dagger.#Secret

    // Application deployment target.
    deployTarget: string | *null

    // How to package the application.
    packageAs: string | *null

    // Database drvier type.
    databaseDriver: string | *"postgres"

    // Meta version tag.
    version: string

    outputs: remote: _commit.output

    // Tag the source.
    // _tag: commitizen.#Bump & {
    //     if deployTarget == "kubernetes" {
    //         source: _k8s.kustomize.output
    //     }
    //     amend: [".trustacks"]
    // }

    // Commit the source tag.
    _commit: fastapi.#Commit & {
        if deployTarget == "kubernetes" {
            source: _k8s.kustomize.output
        }
        remote:     vars."gitRemote"
        privateKey: secrets."gitPrivateKey"
        "version":  version
    }

    _k8s: {
        if deployTarget == "kubernetes" {
            // Container image ref.
            _imageRef: "\(vars."registryHost")/\(vars."project"):\(version)"

            // Create the database password secret.
            _databasePassword: kubectl.#GenericSecret & {
                name:      "database-password"
                namespace: vars."project"
                dryRun:    "client"
                literals: {
                    password: secrets."databasePassword"
                }
            }

            // Encrypt the database password.
            _sopsDatabasePassword: sops.#Encrypt & {
                source: _databasePassword.output
                path:   "secret.yaml"
                regex:  "^(data|stringData)$"
                key:    vars."agePublicKey"
            }

            // Create the kubernetes registry secret.
            _registrySecret: kubectl.#DockerRegistrySecret & {
                name:      "registry-secret"
                namespace: vars."project"
                server:    vars."registryHost"
                username:  vars."registryUsername"
                password:  secrets."registryPassword"
                dryRun:    "client"
            }

            // Encrypt the registry secret.
            _sopsRegistrySecret: sops.#Encrypt & {
                source: _registrySecret.output
                path:   "secret.yaml"
                regex:  "^(data|stringData)$"
                key:    vars."agePublicKey"
            }

            _postgres: {
                if databaseDriver == "postgres" {
                    _changelog: core.#ReadFile & {
                        input: source
                        path:  "liquibase/db.changelog.yaml"
                    }

                    _changelogConfigmap: kubectl.#ConfigMap & {
                        name:      "database-changelog"
                        namespace: vars."project"
                        dryRun:    "client"
                        fromLiterals: {
                            changelog: _changelog.contents
                        }
                    }
                    databaseChangelog: core.#ReadFile & {
                        input: _changelogConfigmap.output
                        path:  "configmap.yaml"
                    }
                }
            }

            // Configure the kustomize assets.
            kustomize: fastapi.#Kustomize & {
                input:            source
                "assets":         assets
                registrySecret:   _sopsRegistrySecret.output
                databasePassword: _sopsDatabasePassword.output
                if databaseDriver == "postgres" {
                    databaseChangelog: _postgres.databaseChangelog.contents
                }

                values: {
                    image:            _imageRef
                    name:             vars."project"
                    databaseName:     vars."databaseName"
                    databaseHost:     vars."databaseHost"
                    databaseUsername: vars."databaseUsername"
                    if databaseDriver == "postgres" {
                        databaseDriver:  "postgres"
                        databaseJdbcUrl: "postgresql://\(vars."databaseHost"):5432/\(vars."databaseName")"
                    }
                }
            }
        }
    }
}
