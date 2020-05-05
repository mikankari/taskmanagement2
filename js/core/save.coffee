
FileSystemExtra = require "fs-extra"

module.exports = (filePath, tasks) ->
    Promise.resolve()
    .then ->
        FileSystemExtra.writeJSON filePath, tasks
