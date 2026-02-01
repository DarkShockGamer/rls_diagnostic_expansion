angular.module('beamng.stuff')
.controller('DiagnosticsMenuController', ['$scope', '$state', '$stateParams', function($scope, $state, $stateParams) {
  if ($scope._initialized) return;
  $scope._initialized = true;

  $scope.diagnostics = {};
  $scope.diagnosticsTimestamp = (new Date()).toLocaleString();
  $scope.goBack = function() { $state.go('computer'); };

  var raw = $stateParams.vehicleId;
  console.log("diagnosticsMenu.js: entering diagnostics, vehicle id (raw):", raw);

  if (!raw || raw === ':vehicleId') {
    console.log("diagnosticsMenu.js: invalid/missing vehicleId, aborting.");
    $scope.diagnostics = { error: "No vehicle selected. Cannot display diagnostics.", damagedParts: [] };
    return;
  }

  var vid = parseInt(raw, 10);
  console.log("diagnosticsMenu.js: vehicle id parsed as:", vid);
  if (isNaN(vid)) {
    $scope.diagnostics = { error: "No vehicle selected. Cannot display diagnostics.", damagedParts: [] };
    return;
  }

  bngApi.engineLua(
    'career_modules_inventory.getVehicleDiagnosticsUiData(' + vid + ')',
    function(ret) {
      console.log("diagnosticsMenu.js: diagnostics ret:", ret && ret.error ? ("ERROR: " + ret.error) : "OK");
      $scope.$apply(function() { $scope.diagnostics = ret; });
    }
  );
}])

export default angular.module('diagnosticsMenu', ['ui.router'])
.config(function($stateProvider) {
  $stateProvider.state('diagnostics-menu', {
    url: '/diagnostics-menu/:vehicleId',
    templateUrl: '/ui/modModules/diagnosticMenu/diagnosticsMenu.html',
    controller: 'DiagnosticsMenuController',
  });
});
