package main

#Config: {
    // Variables and secrets.
    inputs: {
        vars: [
            {
                // Project name.
                name: "project"
            },
            {
                // Remote repository url (must begin with: 'ssh://').
                name: "gitRemote"
            },
            {
                // Container registry host.
                name: "registryHost"
            },
            {
                // Container registry auth username.
                name: "registryUsername"
            },
            {
                // Database host address.
                name: "databaseHost"
            },
            {
                // Database name.
                name: "databaseName"
            },
            {
                // Database username.
                name: "databaseUsername"
            },
            {
                // Age public key for sops encryption.
                name: "agePublicKey"
            },
            {
                // Argo CD server (<host>:<port>)
                name: "argo-cd.server"
            }
        ]
        secrets: [
            {
                // Remote repository ssh private key.
                name: "gitPrivateKey"
            },
            {
                // Container registry auth password.
                name: "registryPassword"
            },
            {
                // Database password.
                name: "databasePassword"
            },
            {
                // Argo CD auth password.
                name: "argo-cd.password"
            },
        ]
    }
}
