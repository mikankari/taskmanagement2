
ChildPorcess = require "child-process-promise"

module.exports = (task) ->
    options = {
        cwd: task.dir
    }

    Promise.resolve()
    .then ->
        ChildPorcess.exec "git remote get-url origin", options
    .then (result) ->
        match = result.stdout.trim().match /^git@github.com:(.*).git$/
        match = result.stdout.trim().match /^https:\/\/github.com\/(.*).git$/ if not match

        throw "not supported remote" if not match

        task.repo = match[1]
        task
