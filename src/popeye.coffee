popeye = (angular) ->
  "use strict"

  mod = angular.module "pathgather.popeye", []

  mod.provider "Popeye", () ->
    PopeyeProvider = {
      # Default options for all Popeye modals. To set these, configure the PopeyeProvider at startup:
      #
      # testApp = angular.module("test", ["pathgather.popeye"]);
      # testApp.config(function(PopeyeProvider) {
      #   PopeyeProvider.defaults.containerClass = "my-modal-window";
      # });
      defaults:
        containerTemplate: """
          <div class="popeye-modal-container">
            <div class="popeye-modal">
              <a class="popeye-close-modal" href ng-click="$close()"></a>
            </div>
          </div>
        """
        containerTemplateUrl: null
        bodyClass: "popeye-modal-open"
        containerClass: null
        modalClass: null
        locals: null
        resolve: null
        scope: null
        controller: null
        keyboard: true
        click: true

      $get: ($q, $animate, $rootScope, $document, $http, $templateCache, $compile, $controller, $injector) ->

        # Modal instances co-operatively manage this state so that everything works nicely
        # (in other words... here are some global variables we use)
        currentModal = null
        pendingPromise = null

        # Register a global keydown handler to detect ESC keypresses
        $document.on "keydown", (evt) ->
          if evt.which == 27 && currentModal? && currentModal.options.keyboard
            currentModal.close(reason: "keyboard")

        # Our modal class, which is responsible for resolving it's controller dependencies, adding/removing itself from
        # the DOM, and co-operating with other instances to ensure only one modal is active at a time
        class PopeyeModal
          constructor: (options = {}) ->
            throw new Error("template or templateUrl must be provided") unless options.template? || options.templateUrl?
            @options = angular.extend(angular.copy(PopeyeProvider.defaults), options)

            # Setup up our resolved, opened, and closed promises
            @resolvedDeferred = $q.defer()
            @resolved = @resolvedDeferred.promise
            @openedDeferred = $q.defer()
            @opened = @openedDeferred.promise
            @closedDeferred = $q.defer()
            @closed = @closedDeferred.promise

          # Setup the modal scope, resolve controller locals, etc.
          # Returns the @resolved promise that resolves when complete
          resolve: =>
            return @resolved if @resolving
            @resolving = true
            $q.when({}).then =>
              locals = angular.extend({ modal: @ }, @options.locals)
              resolve = angular.extend({}, @options.resolve)
              angular.forEach resolve, (value, key) ->
                locals[key] = if angular.isString(value) then $injector.get(value) else $injector.invoke(value, null, locals)
              $q.all(locals)
            .then (resolved) =>
              @scope = if @options.scope? then @options.scope else $rootScope.$new()
              @scope.$close = => @close(arguments...) # Add $close() to the scope, for convenience
              if @options.controller
                @controller = $controller(@options.controller, angular.extend({$scope: @scope}, resolved))
              @resolvedDeferred.resolve(@)
            , (error) =>
              @handleError(error)
            return @resolved

          # Load the container & modal templates, and add everything to the DOM via $animate
          # Returns the @opened promise that resolves when complete
          open: =>
            return @opened if @opening
            @opening = true

            # Don't simply start opening this modal - check to see if there's already an active one (or one in the process
            # of opening), tell it to close, and wait for that before opening ourself
            promise = if pendingPromise?
              # Wait for the pending modal to open...then close it...then return ourself!
              pendingPromise = pendingPromise.then (prevModal) =>
                prevModal.close().then => @
            else if currentModal?
              pendingPromise = currentModal.close().then => @
            else
              pendingPromise = @opened
              $q.when()

            # Once we've ensured that all other modals are cleaned up, start opening ourself
            promise.then =>
              @resolve().then =>
                throw new Error("@scope is undefined") unless @scope?

                # Construct a promise to fetch the modal container template
                containerPromise = if @options.containerTemplate?
                  $q.when({data: @options.containerTemplate})
                else if @options.containerTemplateUrl?
                  $http.get(@options.containerTemplateUrl, {cache: $templateCache})
                else
                  $q.reject("Missing containerTemplate or containerTemplateUrl")

                containerPromise.then (containerTmpl) =>
                  # Configure the modal container
                  containerElement = angular.element(containerTmpl.data)
                  containerElement.addClass(@options.containerClass) if @options.containerClass

                  # Construct a promise to fetch the modal template
                  templatePromise = if @options.template?
                    $q.when({data: @options.template})
                  else if @options.templateUrl?
                    $http.get(@options.templateUrl, {cache: $templateCache})
                  else
                    $q.reject("Missing containerTemplate or containerTemplateUrl")

                  templatePromise.then (tmpl) =>
                    angular.element(containerElement[0].querySelector(".popeye-modal")).append(tmpl.data)
                    if @options.click
                      containerElement.on "click", (evt) => @close() if evt.target == evt.currentTarget
                    @container = $compile(containerElement)(@scope)
                    @element = angular.element(@container[0].querySelector(".popeye-modal"))
                    @element.addClass(@options.modalClass) if @options.modalClass

                    # Add the container to the body
                    body = $document.find("body")
                    bodyLastChild = angular.element(body[0].lastChild) if body[0].lastChild
                    body.addClass(@options.bodyClass) if @options.bodyClass

                    $animate.enter(@container, body, bodyLastChild).then =>
                      currentModal = @
                      @openedDeferred.resolve(@)
            .catch (error) =>
              @handleError(error)
            .finally ->
              pendingPromise = null
            return @opened

          # Remove the modal container from the DOM via $animate
          # Returns the @closed promise that resolves when complete
          close: (value) =>
            return @closed if @closing
            @closing = true
            @opened.then =>
              throw new Error("@container is undefined") unless @container?
              $animate.leave(@container).then =>
                currentModal = null
                # only destroy the scope if we created it
                @scope.$destroy() unless @options.scope
                $document.find("body").removeClass(@options.bodyClass)
                @closedDeferred.resolve(value)
              , (error) =>
                @handleError(error)
            return @closed

          handleError: (error) =>
            @resolvedDeferred.reject(error)
            @openedDeferred.reject(error)
            @closedDeferred.reject(error)

        # The Popeye API
        return {
          openModal: (options = {}) ->
            modal = new PopeyeModal(options)
            modal.open()
            return modal

          closeCurrentModal: (value) ->
            currentModal?.close(value)
            return currentModal

          isModalOpen: () ->
            return !!currentModal
        }
    }


# Check for angular on the window; otherwise, use require() to find it
if window?.angular?
  popeye(window.angular)
else if typeof require == "function"
  angular = require "angular"
  popeye(angular)
else
  throw new Error("Could not find angular on window nor via require()")

# Define CommonJS-style module.exports
if module?
  module.exports = "pathgather.popeye"
