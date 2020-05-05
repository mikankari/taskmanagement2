
ChildPorcess = require "child-process-promise"
FileSystem = require "fs"
Request = require "request-promise"

module.exports = (task, config, templateDir) ->
    options = {
        cwd: task.dir
    }

    Promise.resolve()
    .then ->
        ChildPorcess.exec "git commit --allow-empty -m \"WIP 用の空コミット\"", options
    .then (result) ->
        ChildPorcess.exec "git push origin #{task.head}", options
    .then ->
        new Promise (resolve, reject) ->
            FileSystem.readFile "#{templateDir}/#{task.repo}.md", {encoding: "utf8"}, (error, data) ->
                resolve if error? then "" else data
    .then (data) ->
        title = if task.refs?.number? then "[WIP] refs ##{task.refs.number} #{task.refs.title}" else "[WIP] Untitled"
        body = data.replace /{{\s*?([\w\.]+)\s*}}/g, (match, $1) ->
            $1.split "."
                .reduce ((current, key) -> current[key] or []), task

        Request {
            "uri": "https://api.github.com/repos/#{task.repo}/pulls"
            "method": "POST"
            "headers": {
                "User-Agent": 'taskmanagement v2'
                "Authorization": "token #{config.github.access_token}"
            }
            "body": {
                "title": title
                "body": body
                "head": task.head
                "base": task.base
            }
            "json": true
        }
    .then (data) ->
        task.number = data.number

        task
