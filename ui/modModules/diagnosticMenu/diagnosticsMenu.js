angular.module('beamng.stuff')
.controller('DiagnosticsMenuController', ['$scope', '$state', '$stateParams', function($scope, $state, $stateParams) {
  $scope.diagnostics = {};
  $scope.diagnosticsTimestamp = (new Date()).toLocaleString();
  $scope.goBack = function() { $state.go('computer'); };

  var vid = parseInt($stateParams.vehicleId, 10);
  console.log("diagnosticsMenu.js: entering diagnostics, vehicle id:", $stateParams.vehicleId, "parsed as", vid);
  if (!$stateParams.vehicleId || isNaN(vid)) {
    $scope.diagnostics = { error: "No vehicle selected. Cannot display diagnostics.", damagedParts: [] };
    return;
  }


  bngApi.engineLua(
    'career_modules_inventory.getVehicleDiagnosticsUiData(' + vid + ')',
    function(ret) {
      $scope.$apply(function() { $scope.diagnostics = ret; });
    }
  );
}])

export default angular.module('diagnosticsMenu', ['ui.router'])
.config(function($stateProvider) {
  $stateProvider.state('diagnostics-menu', {
    url: '/diagnostics-menu/:vehicleId',   // <- Note the :vehicleId part!
    templateUrl: '/ui/modModules/diagnosticsMenu/diagnosticsMenu.html',
    controller: 'DiagnosticsMenuController',
  });
});