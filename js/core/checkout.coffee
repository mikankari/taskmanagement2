
ChildPorcess = require "child-process-promise"

module.exports = (task) ->
    options = {
        cwd: task.dir
    }

    Promise.resolve()
    .then ->
        if not task.number?
            ChildPorcess.exec "git fetch && git checkout --no-track -b #{task.head} origin/#{task.base}", options
        else if task.type is "created"
            ChildPorcess.exec "git checkout #{task.head}", options
        else if task.type is "review"
            ChildPorcess.exec "git fetch && git checkout origin/#{task.head}", options
    .then ->
        task
