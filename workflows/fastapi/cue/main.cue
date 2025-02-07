package main

import (
    "strings"

    "dagger.io/dagger"
    "dagger.io/dagger/core"

    // "trustacks.io/commitizen"
    "trustacks.io/fastapi"
)

dagger.#Plan & {
    client: {
        filesystem: {
            "/src":       read: contents: dagger.#FS
            "/mnt":       read: contents: dagger.#FS
            "/assets":    read: contents: dagger.#FS
            "/artifacts": read: contents: dagger.#FS

            if client.env.PACKAGE == "container" {
                "/artifacts/build": write: contents: actions.setup.configure.build
            }
        }
        env: {
            PACKAGE:  string | *"container"
            TARGET:   string | *"kubernetes"
            DATABASE: string | *"postgres"
        }
    }
    actions: {
        _assets:    client.filesystem."/assets".read.contents
        _artifacts: client.filesystem."/artifacts".read.contents
        _config:    #Config
        
        // Load the input variables and secrets.
        _inputs: #Inputs & {
            mounts: client.filesystem."/mnt".read.contents
            inputs: _config.inputs
        }

        // Generate the build version.
        setup: {
            // // Fetch the next semantic version.
            // _version: commitizen.#Version & {
            //     source: _source
            // }
            // // output:  _version.output
            // version: _version.version
 
            // Configure the source.
            configure: fastapi.#Configure & {
                "source":   client.filesystem."/src".read.contents
                remote:     _inputs.vars."gitRemote"
                privateKey: _inputs.secrets."gitPrivateKey"
            }
        }
        _source: setup.configure.output
        
        // setup: {
        //     _version: fastapi.#Version & {
        //         source: _source
        //     }
        //     version: _version.output
        // }

        // Nop.
        build: core.#Nop & {
            _noop: core.#Source & {
                path: "./"
            }
            input: _noop.output
        }

        // test: core.#Nop & {
        //     _noop: core.#Source & {
        //         path: "./"
        //     }
        //     input: _noop.output
        // }

        // "package": core.#Nop & {
        //     _noop: core.#Source & {
        //         path: "./"
        //     }
        //     input: _noop.output
        // }

        // publish: core.#Nop & {
        //     _noop: core.#Source & {
        //         path: "./"
        //     }
        //     input: _noop.output
        // }

        // Run unit tests and lint.
        test: #Test & {
            source: _source
        }

        // Build the react bundle.
        "package": #Package & {
            _version: #Artifact & {
                input: _artifacts
                path:  "build"
            }

            source:    _source
            assets:    _assets
            vars:      _inputs.vars
            secrets:   _inputs.secrets
            version:   _version.output.contents
            packageAs: client.env.PACKAGE
        }

        // Publish the application.
        publish: #Publish & {
            _version: #Artifact & {
                input: _artifacts
                path:  "build"
            }

            source:       _source
            assets:       _assets
            vars:         _inputs.vars
            secrets:      _inputs.secrets
            version:      _version.output.contents
            deployTarget: client.env.TARGET
            packageAs:    client.env.PACKAGE
        }

        stage: #Deploy & {
            _version: #Artifact & {
                input: _artifacts
                path:  "build"
            }

            vars:         _inputs.vars
            secrets:      _inputs.secrets
            version:      _version.output.contents
            deployTarget: client.env.TARGET
        }
    }
}

#Artifact: {
    input: dagger.#FS

    kind: string | *"file"

    path: string

    if kind == "fs" {
        _fs: core.#Subdir & {
            "input": input
            "path":  path
        }
        output: _fs.output
    }

    if kind == "file" {
        _file: core.#ReadFile & {
            "input": input
            "path":  path
        }
        output: _file
    }
}

// Variable and secret inputs.
#Inputs: {
    // Variable and secrets filesystem mount.
    mounts: dagger.#FS

    // Variables and secrets.
    inputs: {
        vars:    [...{name: string, trim: bool | *true}]
        secrets: [...{name: string, trim: bool | *false}]
    }
    
    // Rendered variables and secrets.
    vars: [name=string]: string
    _vars: {
        for var in inputs.vars {
            "\(var.name)": {
                if var.trim == true {
                    value: strings.TrimSpace(_var.contents)
                }
                if var.trim == false {
                    value: _var.contents
                }
                _var: core.#ReadFile & {
                    input: mounts
                    path:  "vars/\(var.name)"
                }
            }
        }
    }
    for name, var in _vars {
        vars: "\(name)": var.value
    }

    secrets: [name=string]: dagger.#Secret
    _secrets: {
        for secret in inputs.secrets {
            "\(secret.name)": {
                value: _secret.output
                _secret: core.#NewSecret & {
                    input: mounts
                    path:  "secrets/\(secret.name)"
                    if secret.trim == true {
                        trimSpace: true
                    }
                }
            }
        }
    }
    for name, secret in _secrets {
        secrets: "\(name)": secret.value
    }
}