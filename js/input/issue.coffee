
Request = require "request-promise"
Moment = require "moment"
Moment.locale "ja"

module.exports = (task, config) ->
    return task if not task.refs?.number?

    Promise.resolve()
    .then ->
        Request {
            "uri": "https://api.github.com/repos/#{task.repo}/issues/#{task.refs.number}"
            "headers": {
                "User-Agent": 'taskmanagement v2'
                "Authorization": "token #{config.github.access_token}"
            }
            "json": true
        }
    .then (data) ->
        dueDate = Moment data.milestone?.due_on

        task.refs.title = data.title
        task.refs.dueDate = dueDate.valueOf()
        task.refs.dueDateFromNow = dueDate.fromNow()
        task.refs.priority = 0

        task
