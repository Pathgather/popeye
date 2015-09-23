angular = require "angular"
ngAnimate = require "angular-animate"
popeye = require "../../release/popeye"
mod = angular.module "pgPopeyeDemoApp", [popeye, ngAnimate]

mod.config (PopeyeProvider) ->
  PopeyeProvider.defaults.containerClass = "demo-container"
  PopeyeProvider.defaults.modalClass = "demo-modal"

mod.controller "pgPopeyeDemoCtrl", (Popeye) ->
  @balloons = false

  @hello = =>
    @balloons = true
    modal = Popeye.openModal(
      template: """
        <h2>Hello, Popeye!</h2>
        <img src="img/littleguys_1.png" />
        <p>Popeye doesn't try to do anything fancy; it compiles your template and appends it to the body.</p>
        <a href class="button close-button" ng-click="modalCtrl.again()">Again!</a>
      """
      controller: "pgPopeyeModalCtrl as modalCtrl"
    )
    modal.closed.then => @balloons = false

  @zoom = =>
    Popeye.openModal(
      template: "<h2>Zoom!</h2>"
      containerClass: "demo-container zoom"
    )

  @small = =>
    Popeye.openModal(
      template: "<h2>Small</h2>"
      modalClass: "demo-modal small"
    )

  @boring = =>
    Popeye.openModal(
      template: "<h2>Boring.</h2>"
      containerClass: "demo-container boring"
    )

  return @

mod.controller "pgPopeyeModalCtrl", (modal, Popeye) ->
  @close = ->
    modal.close()

  @again = ->
    Popeye.openModal(
      template: """
        <h2>No-Mess Modals!</h2>
        <img src="img/littleguys_2.png" />
        <p>Popeye makes sure only one modal is active. No modal stack, no dependencies, no mess. Let's check it out!</p>
        <a href class="button close-button" ng-click="modalCtrl.close()">Close</a>
      """
      controller: "pgPopeyeModalCtrl as modalCtrl"
    )

  return @

mod.directive "pgBalloons", ($interval, $timeout) ->
  restrict: "A"
  scope:
    pgBalloons: "="

  template: """
    <div class="pg-balloon-container ng-animate" ng-style="{ left: offset }" ng-repeat="offset in balloonOffsets track by $index" >
      <div pg-balloon ></div>
    </div>
  """
  link: (scope, element, attrs) ->
    scope.balloonOffsets = []
    creatingBalloons = null

    addBalloon = -> scope.balloonOffsets.push((Math.random() * 70) + 15 + "%");
    removeBalloons = -> scope.balloonOffsets = []

    scope.$watch "pgBalloons", (newVal, oldVal) ->
      if oldVal != newVal
        if newVal
          creatingBalloons = $interval(addBalloon, 200)
          $timeout ->
            $interval.cancel(creatingBalloons)
            creatingBalloons = null
          , 3000
        else
          $interval.cancel(creatingBalloons)
          creatingBalloons = null
          removeBalloons()

mod.directive "pgBalloon", ->
  restrict: "A"
  template: """
    <div class="pg-balloon">
      <div class="pg-balloon-knot">
        <div class="pg-balloon-tail">
          <div class="pg-balloon-tail">
            <div class="pg-balloon-tail">
              <div class="pg-balloon-tail">
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  """
