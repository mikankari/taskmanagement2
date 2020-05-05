define (require, exports, module) ->

    ExtensionUtils = brackets.getModule "utils/ExtensionUtils"
    NodeDomain = brackets.getModule "utils/NodeDomain"
    NativeApp = brackets.getModule "utils/NativeApp"
    WorkspaceManager = brackets.getModule "view/WorkspaceManager"
    ProjectManager = brackets.getModule "project/ProjectManager"
    Dialogs = brackets.getModule "widgets/Dialogs"

    extension_id = "taskmanagement"
    extension_path = ExtensionUtils.getModulePath module

    createPanel = ->
        $ require "text!html/panel.html"
            .find ".#{extension_id}-btn-add-created"
                .on "click", handleAddCreated
                .end()
            .find ".#{extension_id}-btn-add-review"
                .on "click", handleAddReview
                .end()
            .find ".#{extension_id}-btn-reload"
                .on "click", handleReload
                .end()
            .find ".#{extension_id}-btn-show-all"
                .on "click", handleShowAll
                .end()
            .find ".#{extension_id}-btn-copy"
                .on "click", handleCopy
                .end()
            .find ".#{extension_id}-btn-write-diary"
                .on "click", handleWriteDialy
                .end()
            .find ".close"
                .on "click", handleIconClicked
                .end()

    handleAddCreated = ->
        dialog = Dialogs.showModalDialogUsingTemplate createAddCreatedDialog()

        Promise.resolve()
        .then ->
            dialog.getPromise()
        .then (buttonId) ->
            throw buttonId if buttonId isnt "ok"

            domain.exec "addCreated", {
                dir: ProjectManager.getProjectRoot()._path
                refs: {
                    number: dialog.getElement().find('[name="refs_number"]').val()
                }
                head: dialog.getElement().find('[name="head"]').val()
                base: dialog.getElement().find('[name="base"]').val()
            }
        .then ->
            Dialogs.showModalDialog "create-pr", "Create PR", "Done"
                .getPromise()
        .catch (error) ->
            Dialogs.showModalDialog "create-pr", "Create PR", JSON.stringify error

    createAddCreatedDialog = ->
        $ require "text!html/add-created-dialog.html"
            .find "[name='pwd']"
                .val ProjectManager.getProjectRoot()._path
                .end()

    handleAddReview = ->
        dialog = Dialogs.showModalDialogUsingTemplate createAddReviewDialog()

        Promise.resolve()
        .then ->
            dialog.getPromise()
        .then (buttonId) ->
            throw buttonId if buttonId isnt "ok"

            domain.exec "addReview", {
                dir: ProjectManager.getProjectRoot()._path
                url: dialog.getElement().find('[name="url"]').val()
            }
        .then ->
            Dialogs.showModalDialog "review-pr", "Review PR", "Done"
                .getPromise()
        .catch (error) ->
            Dialogs.showModalDialog "review-pr", "Review PR", JSON.stringify error

    createAddReviewDialog = ->
        $ require "text!html/add-review-dialog.html"
            .find "[name='pwd']"
                .val ProjectManager.getProjectRoot()._path
                .end()

    handleShowAll = ->
        $ ".#{extension_id}-inprogressable"
            .toggle()

    handleCopy = (item) ->
        $ ".#{extension_id}-task-copy-text"
            .select()
        document.execCommand "copy"

    handleWriteDialy = ->
        Promise.resolve()
        .then ->
            buttons = [
                {
                    className: Dialogs.DIALOG_BTN_CLASS_LEFT
                    id: Dialogs.DIALOG_BTN_CANCEL
                    text: "Cancel"
                }
                {
                    className: Dialogs.DIALOG_BTN_CLASS_PRIMARY
                    id: Dialogs.DIALOG_BTN_OK
                    text: "Write"
                }
            ]
            Dialogs.showModalDialog "write-diary", "Write diary", "Are you sure?", buttons
                .getPromise()
        .then (buttonId) ->
            throw buttonId if buttonId isnt Dialogs.DIALOG_BTN_OK

            domain.exec "writeDiary"
        .then ->
            Dialogs.showModalDialog "write-diary", "Write diary", "Done"
                .getPromise()
        .catch (error) ->
            Dialogs.showModalDialog "write-diary", "Write diary", JSON.stringify error

    createIcon = ->
        $ "<a href=\"#\"></a>"
            .css {
                "backgroundImage": "url(\"#{extension_path}icon.svg\")"
                "backgroundPosition": "0 0"
                "backgroundSize": "100%"
            }
            .on "click", handleIconClicked

    handleIconClicked = ->
        panel.setVisible isVisible = not panel.isVisible()

        icon.css {
            "backgroundPosition": "0 #{if isVisible then "-48px" else "0"}"
        }

        handleReload() if isVisible

    handleReload = ->
        $ "##{extension_id} table"
            .empty()

        domain.exec "list"
            .then (tasks) ->
                console.log tasks

                tasks.forEach (item) ->
                    tableRow.clone()
                        .find ".#{extension_id}-task-title"
                            .text item.title
                            .end()
                        .find ".#{extension_id}-task-checkout"
                            .on "click", (event) -> handleCheckout item, event
                            .end()
                        .find ".#{extension_id}-task-open-pr"
                            .on "click", -> handleOpenPR item
                            .end()
                        .find ".#{extension_id}-task-current"
                            .text item.todos[item.currentIndex]?.name or "＼ｵﾜﾀ／"
                            .end()
                        .find ".#{extension_id}-task-due-date"
                            .text item.refs?.dueDateFromNow
                            .end()
                        .toggleClass "#{extension_id}-inprogressable", not item.progressable
                        .toggle item.progressable
                        .appendTo "##{extension_id} table"

                copyText = tasks
                    .map (item) -> [
                            "- [#{item.title}](#{item.url})"
                            "  - #{item.todos[item.currentIndex]?.name or "＼ｵﾜﾀ／"}"
                            ""
                        ].join "\n"
                    .join "\n"
                $ ".#{extension_id}-task-copy-text"
                    .text copyText
            .fail (error) ->
                Dialogs.showModalDialog "load-tasks", "Load tasks", JSON.stringify error

    handleCheckout = (item, event) ->
        $ ".#{extension_id}-task-head"
            .hide()
        domain.exec "checkout", item
            .then ->
                $ event.target
                    .parents "tr"
                    .find ".#{extension_id}-task-head"
                    .show()
            .fail (error) ->
                Dialogs.showModalDialog "checkout", "Checkout", JSON.stringify error

    handleOpenPR = (item) ->
        NativeApp.openURLInDefaultBrowser item.url

    domain = new NodeDomain extension_id, "#{extension_path}domain"
    domain.exec "initialize", { domain_path: extension_path }
        .fail (error) ->
            Dialogs.showModalDialog "initialize", "Initialize", JSON.stringify error

    panel = WorkspaceManager.createBottomPanel "io.github.mikankari.#{extension_id}", createPanel(), 100

    tableRow = $ "##{extension_id} tr"
        .find ".label"
            .hide()
            .end()
        .remove()

    icon = createIcon()
        .appendTo $ "#main-toolbar .buttons"
