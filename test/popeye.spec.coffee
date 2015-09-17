"use strict";

describe "pathgather.popeye", ->
  beforeEach ->
    # Define a test app so we can make sure that we load things like controllers correctly
    testApp = angular
      .module("test", ["pathgather.popeye"])
      .config ($provide) ->
        # $animate uses $$asyncCallback that uses requestAnimationFrame by default, but it doesn"t test well, so we use $timeout
        $provide.decorator "$$asyncCallback", ($delegate, $timeout) ->
          return (fn) -> $timeout(fn, 0, false)
      .controller "TestCtrl", ($scope, data) ->
        @ctrlAsData = data
        $scope.ctrlData = data

    angular.mock.module("test")

  describe "Popeye", ->
    beforeEach inject (Popeye, $document, $rootScope, $templateCache, $q, $timeout, $animate) ->
      [@Popeye, @$document, @$rootScope, @$templateCache, @$q, @$timeout, @$animate] = arguments
      spyOn(@$templateCache, "get").and.callFake (filename) ->
        return {
          "modal_template.html": "
            <div class='scope-data' ng-bind='data'></div>
            <div class='ctrl-data' ng-bind='ctrlData'></div>
            <div class='ctrl-as-data' ng-bind='testCtrl.ctrlAsData'></div>
          "
          }[filename]

    describe "openModal", ->
      describe "with no options", ->
        it "throws an error", ->
          expect(=> @Popeye.openModal()).toThrowError(Error, /template/)

      describe "with a templateUrl", ->
        beforeEach ->
          @modal = @Popeye.openModal(templateUrl: "modal_template.html")

        it "returns an object that exposes useful things", ->
          # Before opening, all promises should be defined
          expect(@modal).toBeDefined()
          expect(@modal.resolved).toBeDefined()
          expect(@modal.opened).toBeDefined()
          expect(@modal.closed).toBeDefined()
          expect(@modal.scope).not.toBeDefined()
          expect(@modal.element).not.toBeDefined()

          # After opening, scope and elements should be defined too
          @$rootScope.$digest()
          expect(@modal.scope).toBeDefined()
          expect(@modal.container).toBeDefined()
          expect(@modal.element).toBeDefined()

        it "loads the templates", ->
          @$rootScope.$digest()
          expect(@$templateCache.get).toHaveBeenCalledWith("modal_template.html")

        it "appends the element to the body", ->
          @$rootScope.$digest()
          expect(@modal.element).toBeInDOM()

        it "adds a class to the body indicating that the modal is open", ->
          @$rootScope.$digest()
          expect(angular.element("body").hasClass("modal-open")).toBe(true)

        it "appends the element to the body when body is empty", ->
          angular.element("body").empty()
          @modal = @Popeye.openModal(templateUrl: "modal_template.html")
          @$rootScope.$digest()
          @$timeout.flush()
          expect(@modal.element).toBeInDOM()

        it "resolves the modal's opened promise", ->
          opened = false
          @modal.opened.then -> opened = true
          @$timeout.flush()
          expect(opened).toBe(true)

        it "resolves the modal's closed promise with the close value", ->
          @modal.closed.then (result) =>
            @closed_value = result
          @modal.close("hello")
          @$timeout.flush()
          expect(@closed_value).toBe("hello")

        describe "adds a click handler to the container that", ->
          beforeEach ->
            @$rootScope.$digest()
            @closed = false
            @modal.closed.then (result) =>
              @closed = true
              @closed_value = result

          it "closes modal when clicked on the container", ->
            @modal.container.trigger("click")
            @$timeout.flush()
            expect(@closed).toBe(true)
            expect(@closed_value).toEqual(reason: "backdrop click")

          it "doesn't close modal when clicked on the modal body", ->
            @modal.container.find(".pg-modal").trigger("click")
            @$timeout.flush()
            expect(@closed).toBe(false)

      describe "with a template", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            template: "<div class='my-class'>This is my template</div>"
          )

        it "loads the template", ->
          @$rootScope.$digest()
          # Our test controller binds the 'data' resolve to a scope variable 'ctrlData'
          expect(@modal.element.find(".my-class").text()).toEqual("This is my template")

      describe "with a template and templateUrl", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            template: "<div class='my-class'>This is my template</div>"
            templateUrl: "modal_template.html"
          )

        it "loads the template, not the templateUrl", ->
          @$rootScope.$digest()
          # Our test controller binds the 'data' resolve to a scope variable 'ctrlData'
          expect(@modal.element.find(".my-class").text()).toEqual("This is my template")
          expect(@modal.element.find(".scope-data").length).toEqual(0)

      describe "with a containerTemplate", ->
        beforeEach ->
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            containerTemplate: "<div class='pg-modal-container'><div class='my-header'></div><div class='pg-modal'></div></div>"
          )

        it "uses the provided container template", ->
          @$rootScope.$digest()
          expect(@modal.container.find(".my-header").length).toEqual(1)

      describe "with a containerTemplateUrl", ->
        beforeEach ->
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            containerTemplate: null
            containerTemplateUrl: "my_modal_container.html"
          )

        it "requests the container template", inject ($httpBackend) ->
          $httpBackend.expectGET("my_modal_container.html").respond(
            "<div class='pg-modal-container'><div class='my-header'></div><div class='pg-modal'></div></div>"
          )
          @$rootScope.$digest()
          $httpBackend.flush()
          expect(@modal.container.find(".my-header").length).toEqual(1)
          $httpBackend.verifyNoOutstandingExpectation()
          $httpBackend.verifyNoOutstandingRequest()

      describe "with controller & resolves", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            controller: "TestCtrl"
            resolve: { data: => @data }
          )

        it "exposes a promise that is resolved when the resolves are finished", ->
          modalResolved = null
          @modal.resolved.then (result) -> modalResolved = result
          expect(modalResolved).toBe(null)
          @$rootScope.$digest()
          expect(modalResolved).toEqual(@modal)

        it "injects the modal scope and resolves into the controller", ->
          @$rootScope.$digest()
          # Our test controller binds the 'data' resolve to a scope variable 'ctrlData'
          expect(@modal.scope.ctrlData).toEqual(@data)
          expect(@modal.controller).toBeDefined()
          expect(@modal.element.find(".ctrl-data").text()).toEqual(@data)

      describe "with controllerAs & resolves", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            controller: "TestCtrl as testCtrl"
            resolve: { data: => @data }
          )

        it "injects the modal scope and resolves into the controller", ->
          @$rootScope.$digest()
          # Our test controller binds the 'data' resolve to a variable 'ctrlAsData'
          expect(@modal.controller).toBeDefined()
          expect(@modal.controller.ctrlAsData).toEqual(@data)
          expect(@modal.element.find(".ctrl-as-data").text()).toEqual(@data)

      describe "with windowClass", ->
        beforeEach ->
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            windowClass: "pg-special-window"
          )

        it "adds the class to the container element", ->
          @$rootScope.$digest()
          expect(@modal.container).toHaveClass("pg-special-window")

      describe "with locals", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            controller: "TestCtrl as testCtrl"
            locals: { data: @data }
          )

        it "injects the modal scope and locals into the controller", ->
          @$rootScope.$digest()
          # Our test controller binds the 'data' local to a variable 'ctrlData'
          expect(@modal.controller).toBeDefined()
          expect(@modal.controller.ctrlAsData).toEqual(@data)
          expect(@modal.element.find(".ctrl-as-data").text()).toEqual(@data)

      describe "with scope", ->
        beforeEach ->
          @myScope = @$rootScope.$new()
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            scope: @myScope
            controller: ($scope) ->
              $scope.data = "hello"
          )

        it "injects the provided scope to the modal", ->
          @$rootScope.$digest()
          # Our test controller adds a new "data" property to the scope
          expect(@myScope.data).toBeDefined()
          expect(@myScope.data).toEqual("hello")
          expect(@modal.element.find(".scope-data").text()).toEqual("hello")

        it "doesn't destroy the scope on close", ->
          spyOn(@myScope, "$destroy")
          @modal.close()
          @$rootScope.$digest()
          @$timeout.flush()
          expect(@myScope.$destroy).not.toHaveBeenCalled()

      describe "with scope but no controller", ->
        beforeEach ->
          @myScope = @$rootScope.$new()
          @myScope.data = "hello"
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            scope: @myScope
          )

        it "binds the provided scope to the template", ->
          @$rootScope.$digest()
          expect(@modal.element.find(".scope-data").text()).toEqual("hello")

      describe "when a resolve error occurs", ->
        beforeEach ->
          @data = "foo"
          @modal = @Popeye.openModal(
            templateUrl: "modal_template.html"
            controller: "TestCtrl"
            resolve: { data: => @$q.reject("Oh no!") }
          )

        it "rejects all the modal promises with the error", ->
          resolved = opened = closed = null
          @modal.resolved.catch (error) -> resolved = error
          @modal.opened.catch (error) -> opened = error
          @modal.closed.catch (error) -> closed = error
          @$rootScope.$digest()
          expect(resolved).toEqual("Oh no!")
          expect(opened).toEqual("Oh no!")
          expect(closed).toEqual("Oh no!")

      describe "when a modal is already active", ->
        beforeEach ->
          @modal = @Popeye.openModal(templateUrl: "modal_template.html")
          opened = false
          @modal.opened.then -> opened = true
          @$rootScope.$digest()
          @$timeout.flush()
          expect(opened).toBe(true)

        it "closes the existing modal, then opens the next one", ->
          oldModalClosed = false
          @modal.closed.then -> oldModalClosed = true
          newModal = @Popeye.openModal(templateUrl: "modal_template.html")
          newModalOpened = false
          newModal.opened.then -> newModalOpened = true
          expect(oldModalClosed).toBe(false)
          expect(newModalOpened).toBe(false)
          @$rootScope.$digest()
          @$timeout.flush()
          expect(oldModalClosed).toBe(true)
          expect(newModalOpened).toBe(true)

      describe "when opening multiple modals in series", ->
        it "opens them in calling order, after closing the previous first", ->
          modal1 = @Popeye.openModal(templateUrl: "modal_template.html", id: "modal1")
          modal2 = @Popeye.openModal(templateUrl: "modal_template.html", id: "modal2")
          modal3 = @Popeye.openModal(templateUrl: "modal_template.html", id: "modal3")
          openedModal = "none"
          closedModal = "none"
          modal1.opened.then ->
            expect(openedModal).toEqual("none")
            expect(closedModal).toEqual("none")
            openedModal = "modal1"
          modal1.closed.then ->
            expect(openedModal).toEqual("modal1")
            expect(closedModal).toEqual("none")
            closedModal = "modal1"
          modal2.opened.then ->
            expect(openedModal).toEqual("modal1")
            expect(closedModal).toEqual("modal1")
            openedModal = "modal2"
          modal2.closed.then ->
            expect(openedModal).toEqual("modal2")
            expect(closedModal).toEqual("modal1")
            closedModal = "modal2"
          modal3.opened.then ->
            expect(openedModal).toEqual("modal2")
            expect(closedModal).toEqual("modal2")
            openedModal = "modal3"
          modal3.closed.then ->
            expect(openedModal).toEqual("modal3")
            expect(closedModal).toEqual("modal2")
            closedModal = "modal3"
          @$rootScope.$digest()
          @$timeout.flush()
          expect(openedModal).toEqual("modal3")
          expect(closedModal).toEqual("modal2")

    describe "closeCurrentModal", ->
      beforeEach ->
        @modal = @Popeye.openModal(templateUrl: "modal_template.html")
        @$rootScope.$digest()
        @$timeout.flush()

      it "removes the element from the body", ->
        @Popeye.closeCurrentModal()
        @$rootScope.$digest()
        expect(@modal.element).not.toBeInDOM()

      it "removes the class from the body indicating that the modal is open", ->
        expect(angular.element("body").hasClass("modal-open")).toBe(true)
        @Popeye.closeCurrentModal()
        @$rootScope.$digest()
        @$timeout.flush()
        expect(angular.element("body").hasClass("modal-open")).toBe(false)

      it "resolves the modal's closed promise", ->
        @modal.closed.then (result) =>
          @closed = true
          @closed_value = result
        @Popeye.closeCurrentModal("some reason")
        @$timeout.flush()
        expect(@closed).toBe(true)
        expect(@closed_value).toEqual(reason: "some reason")

      it "destroys the modal scope", ->
        @Popeye.closeCurrentModal()
        @$timeout.flush()
        expect(@modal.scope.$$destroyed).toBe(true)

      it "calls $animate.leave once", ->
        spyOn(@$animate, "leave").and.callThrough()
        @Popeye.closeCurrentModal()
        @Popeye.closeCurrentModal()
        @$rootScope.$digest()
        @Popeye.closeCurrentModal()
        @$rootScope.$digest()
        expect(@$animate.leave.calls.count()).toBe(1)
