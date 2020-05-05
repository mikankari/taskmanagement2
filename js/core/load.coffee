
FileSystemEx = require "fs-extra"

module.exports = (filePath) ->
    Promise.resolve()
    .then ->
        FileSystemEx.readJSON filePath
    .catch ->
        []
    .then (tasks) ->
        tasks = [] if not tasks?
        for item in tasks
            item.previousIndex = if item.todos? then Math.max 0, item.todos.findIndex (todo, index) -> todo.isDone is " " else 0
        tasks
