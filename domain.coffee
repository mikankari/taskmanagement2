Load = null
PullRequest = null
Issue = null
Redmine = null
Checkout = null
Diary = null
Save = null
Publish = null
Repo = null

_domain_id = "taskmanagement"
_domain_path = null

_config = null

_initialize = (payload, callback) ->
    _domain_path = payload.domain_path

    _config = require "#{_domain_path}config.json"

    Load = require "#{_domain_path}js/core/load.js"
    PullRequest = require "#{_domain_path}js/input/pull-request.js"
    Issue = require "#{_domain_path}js/input/issue.js"
    Redmine = require "#{_domain_path}js/input/redmine.js"
    Checkout = require "#{_domain_path}js/core/checkout.js"
    Diary = require "#{_domain_path}js/output/diary.js"
    Save = require "#{_domain_path}js/core/save.js"
    Publish = require "#{_domain_path}js/core/publish.js"
    Repo = require "#{_domain_path}js/core/repo.js"

    callback null

_get = ->
    Promise.resolve()
    .then ->
        Load "#{_domain_path}tasks.json"
    .then (tasks) ->
        Promise.all tasks.map (item) -> PullRequest item, _config
    .then (tasks) ->
        Promise.all tasks.map (item) ->
            switch item.repo
                when "mikankari/test1"
                    Issue item, _config
                else
                    item
    .then (tasks) ->
        tasks.sort (a, b) ->
            # みんな締め切りを設定してくれなくなった
            # a.refs?.dueDate.diff b.refs?.dueDate
            a.createdAt - b.createdAt

_list = (callback) ->
    _get()
    .then (tasks) ->
        callback null, tasks
    .catch (error) ->
        console.error error
        callback error

_writeDiary = (callback) ->
    _get()
    .then (tasks) ->
        Diary tasks, _config, "#{_domain_path}template"
    .then (tasks) ->
        tasks.filter (item) -> item.currentIndex < item.todos.length
    .then (tasks) ->
        Save "#{_domain_path}tasks.json", tasks
    .then ->
        callback null
    .catch (error) ->
        console.error error
        callback error

_checkout = (task, callback) ->
    Promise.resolve()
    .then ->
        Checkout task
    .then ->
        callback null
    .catch (error) ->
        console.error error
        callback error

_addCreated = (payload, callback) ->
    Promise.resolve()
    .then ->
        Repo {
            type: "created"
            dir: payload.dir
            head: payload.head
            base: payload.base
        }
    .then (task) ->
        return task if not payload.refs?.number

        task.refs = {
            number: payload.refs.number
        }
        switch task.repo
            when "mikankari/test1"
                Issue task, _config
            else
                item
    .then (task) ->
        Checkout task
    .then (task) ->
        Publish task, _config, "#{_domain_path}template"
    .then (task) ->
        Promise.resolve()
        .then ->
            Load "#{_domain_path}tasks.json"
        .then (currentTasks) ->
            currentTasks.push task

            Save "#{_domain_path}tasks.json", currentTasks
    .then ->
        callback null
    .catch (error) ->
        console.error error
        callback error

_addReview = (payload, callback) ->
    match = payload.url.match /https\:\/\/github.com\/([\w\d\-\/]+)\/pull\/(\d+)/
    repo = match[1]
    number = match[2]

    Promise.resolve()
    .then ->
        Repo {
            type: "review"
            dir: payload.dir
            number: number
        }
    .then (task) ->
        throw "not match repo" if task.repo isnt repo

        Promise.resolve()
        .then ->
            Load "#{_domain_path}tasks.json"
        .then (currentTasks) ->
            return if currentTasks.some (item) -> item.type is "review" and item.repo is task.repo and item.number is task.number

            currentTasks.push task
            Save "#{_domain_path}tasks.json", currentTasks
    .then ->
        callback null
    .catch (error) ->
        console.error error
        callback error

exports.init = (DomainManager) ->
    if not DomainManager.hasDomain _domain_id
        DomainManager.registerDomain _domain_id, {
            major: 0, minor: 1
        }

    DomainManager.registerCommand _domain_id,
        "initialize",
        _initialize,
        true,
        "initialize",
        [
            {
                name: "domain_path"
                type: "string"
                description: "extension path"
            }
        ],
        []
    DomainManager.registerCommand _domain_id,
        "list",
        _list,
        true,
        "list tasks",
        [],
        [
            {
                name: "tasks"
                type: "object"
                description: ""
            }
        ]
    DomainManager.registerCommand _domain_id,
        "writeDiary",
        _writeDiary,
        true,
        "write to a diary",
        [],
        []
    DomainManager.registerCommand _domain_id,
        "checkout",
        _checkout,
        true,
        "exec git checkout",
        [
            {
                name: "task"
                type: "object"
                description: ""
            }
        ],
        []
    DomainManager.registerCommand _domain_id,
        "addCreated",
        _addCreated,
        true,
        "create and add implement PR",
        [
            {
                name: "payload"
                type: "object"
                description: ""
            }
        ],
        []
    DomainManager.registerCommand _domain_id,
        "addReview",
        _addReview,
        true,
        "add review PR",
        [
            {
                name: "payload"
                type: "object"
                description: ""
            }
        ],
        []
