
Request = require "request-promise"
Moment = require "moment"
Moment.locale "ja"

module.exports = (task, config) ->
    Promise.resolve()
    .then ->
        Request {
            "uri": "https://api.github.com/repos/#{task.repo}/pulls/#{task.number}"
            "qs": {
                "head": "#{task.repo}:#{task.head}"
                "state": "all"
            }
            "headers": {
                "User-Agent": 'taskmanagement v2'
                "Authorization": "token #{config.github.access_token}"
            }
            "json": true
        }
    .then (pr) ->
        task.title = pr.title
        task.url = pr.html_url
        task.head = pr.head.ref
        task.base = pr.base.ref
        task.createdAt = Moment pr.created_at
            .valueOf()

        refsMatch = pr.title.match /(refs|issue) #(\d+) /
        task.refs = {
            number: refsMatch[2]
        } if refsMatch?

        if task.type is "created"
            todosMatch = pr.body.match /\- \[([ x])\] (.*)/g
            task.todos = for todo in todosMatch or []
                {
                    "name": todo.substring 6
                    "isDone": todo.substring 3, 4
                }
        else if task.type is "review"
            Promise.resolve()
            .then ->
                Request {
                    "uri": "https://api.github.com/repos/#{task.repo}/pulls/#{task.number}/reviews"
                    "headers": {
                        "User-Agent": 'taskmanagement v2'
                        "Authorization": "token #{config.github.access_token}"
                    }
                    "json": true
                }
            .then (reviews) ->
                task.todos = for todo in reviews when todo.user.login is config.github.user
                    {
                        "name": "コードレビュー"
                        "isDone": "x"
                    }
                task.todos.push {
                    "name": "コードレビュー"
                    "isDone": " "
                } if pr.state is "open" and pr.requested_reviewers.some (reviewer) -> reviewer.login is config.github.user
                task.todos.push {
                    "name": "マージなど完了"
                    "isDone": if pr.state is "open" then " " else "x"
                }
    .then ->
        currentIndex = task.todos.findIndex (todo, index) -> todo.isDone is " "
        if currentIndex isnt -1
            task.currentIndex = currentIndex
            task.progressable = not task.todos[currentIndex].name.match /(完了|受け取り)( ＼ｵﾜﾀ／)?$/
        else
            task.currentIndex = task.todos.length
            task.progressable = false

        task
