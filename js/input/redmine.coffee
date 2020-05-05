
Request = require "request-promise"
Moment = require "moment"
Moment.locale "ja"

module.exports = (task, config) ->
    return task if not task.refs?.number?

    Promise.resolve()
    .then ->
        Request {
            "uri": "#{config.redmine.base_url}issues/#{task.refs.number}.json"
            "headers": {
                "User-Agent": 'taskmanagement v2'
                "X-Redmine-API-Key": config.redmine.access_token
            }
            "json": true
        }
    .then (data) ->
        dueDate = Moment data.issue?.due_date

        task.refs.title = data.issue?.subject
        task.refs.dueDate = dueDate.valueOf()
        task.refs.dueDateFromNow = dueDate.fromNow()
        task.refs.priority = switch data.issue?.priority.name
            when "低め" then -1
            when "高め" then 1
            when "急いで" then 2
            when "今すぐ" then 3
            else 0

        task
