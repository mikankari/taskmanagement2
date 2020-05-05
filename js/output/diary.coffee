
FileSystem = require "fs"
Request = require "request-promise"
Moment = require "moment"
Moment.locale "ja"

module.exports = (tasks, config, templateDir) ->
    Promise.resolve()
    .then ->
        new Promise (resolve, reject) ->
            FileSystem.readFile "#{templateDir}/diary.md", {encoding: "utf8"}, (error, data) ->
                resolve if error? then "" else data
    .then (diaryTemplate) ->
        Promise.resolve()
        .then ->
            Request {
                "uri": "https://slack.com/api/channels.history"
                "qs": {
                    "token": config.slack.token
                    "channel": config.slack.channel
                    "oldest": Moment {hour: 0}
                        .unix()
                    "count": 1000
                }
                "json": true
            }
        .then (data) ->
            renderTasks = (tasks) ->
                ret = []
                ret.push "<ul>"
                for item in tasks when item.type isnt "review" or item.progressable or item.previousIndex isnt item.todos.length - 1
                    ret.push "  <li>"
                    ret.push "    <div style=\"font-size: 1.4rem;\">"
                    ret.push "      <a href=\"#{item.url}\" target=\"_blank\">#{item.title}</a>"
                    ret.push "    </div>"
                    ret.push "    <ul>"
                    ret.push "      <li>[#{item.todos[index].isDone}] #{item.todos[index].name}</li>" for index in [item.previousIndex..item.currentIndex - 1] if item.previousIndex <= item.currentIndex - 1
                    ret.push "      <li>[#{item.todos[item.currentIndex].isDone}] #{item.todos[item.currentIndex].name}</li>" if item.currentIndex < item.todos.length
                    ret.push "    </ul>"
                    ret.push "    <details style=\"margin: 0 0 1em;\">"
                    ret.push "      <summary style=\"color: #aaa; font-size: 1.2rem;\">もっと後</summary>"
                    ret.push "      <ul>"
                    ret.push "        <li>[#{item.todos[index].isDone}] #{item.todos[index].name}</li>" for index in [item.currentIndex + 1..item.todos.length - 1] if item.currentIndex + 1 <= item.todos.length - 1
                    ret.push "      </ul>"
                    ret.push "    </details>"
                    ret.push "  </li>"
                ret.push "</ul>"
                ret.join "\n"
            diaryParams = {
                currentDate: Moment().format "YYYY/MM/DD"
                otherTasks: []
                withHeaders: []
                comments: []
                createdTasks: renderTasks tasks.filter (item) -> item.type is 'created'
                reviewTasks: renderTasks tasks.filter (item) -> item.type isnt "created"
            }
            for item in data.messages?.reverse() when item.user is config.slack.user
                if item.text.match /\- \[[ x]\] /
                    diaryParams.otherTasks.push item.text.replace /\n/g, "  \n"
                else if item.text.match /^##/
                    diaryParams.withHeaders.push item.text + "\n"
                else
                    diaryParams.comments.push "- " + item.text.replace /\n/g, "  \n"
            diaryParams.otherTasks = diaryParams.otherTasks.join "\n"
            diaryParams.withHeaders = diaryParams.withHeaders.join "\n"
            diaryParams.comments = diaryParams.comments.join "\n"

            diaryTemplate = diaryTemplate?.replace /{{\s*?([\w\.]+)\s*}}/g, (match, $1) ->
                $1.split "."
                    .reduce ((current, key) -> current[key] or []), diaryParams
            splited = diaryTemplate.split "\n"

            {
                title: splited[0] or ""
                tags: splited[1]?.split(",") or []
                body: splited.slice(2).join "\n"
            }
    .then (data) ->
        # console.log data
        Request {
            "uri": "https://api.docbase.io/teams/#{config.docbase.domain}/posts"
            "method": "POST"
            "body": data
            "headers": {
                "X-DocBaseToken": config.docbase.token
                "X-Api-Version": "2"
            }
            "json": true
        }
    .then ->
        tasks
