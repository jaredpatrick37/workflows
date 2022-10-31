package commitizen

import (
    "strings"

    "dagger.io/dagger"

    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

// Bump to the next semantic release version and commit to the tag.
#Bump: {
    // Project source code.
    source: dagger.#FS

    // Bump commit message.
    message: string | *"build: bump $current_version → $new_version [ts-skip-ci]"

    // Commit username.
    gitUsername: string | *"trustacks"

    // Commit email.
    gitEmail: string | *"ci@trustacks.io"

    // Amend files to commit before bump.
    amend: [...string] | *[]

    // Command return code.
    code: _container.export.files."/code"

    // Version bumped source.
    output: _container.export.directories."/output"

    _container: bash.#Run & {
        _image:  #Image
        input:   *_image.output | docker.#Image
        workdir: "/src"

        script: contents: #"""
         # check if latest tag exists.
        if [ ! -z $(git tag -l | awk '{print $1}') ]; then
            latest_tag=$(git describe --tag `git rev-list --tags --max-count=1` || true)
            git checkout tags/$latest_tag -- CHANGELOG.md
            git checkout tags/$latest_tag -- .cz.json
        else
            cat > .cz.json <<EOF
        {
            "commitizen": {
                "bump_message": "$BUMP_MESSAGE",
                "name": "cz_conventional_commits",
                "tag_format": "\$version",
                "update_changelog_on_bump": true,
                "version": "0.0.0"
            }
        }
        EOF
        fi

        git config user.name "$GIT_USERNAME"
        git config user.email "$GIT_EMAIL"
        
        # bump version and amend with included files.
        git add .cz.json
        git add $AMEND_FILES
        git commit --amend --no-edit
        cz bump --yes --changelog
        
        cp -R /src /output
        echo $$ > /code
        """#

        mounts: {
            src: {
                dest:     "/src"
                contents: source
            }
        }

        env: {
            AMEND_FILES:  strings.Join(amend, " ")
            BUMP_MESSAGE: message
            GIT_USERNAME: gitUsername
            GIT_EMAIL:    gitEmail
        }

        export: {
            directories: "/output": dagger.#FS
            files:       "/code":   string
        }
    }
}