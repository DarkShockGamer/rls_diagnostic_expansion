<template>
  <div class="diagnostics-modal-bg">
    <div class="diagnostics-modal">
      <div class="diagnostics-modal-header">
        <h2><span class="icon">🛠️</span> Diagnostics Report</h2>
        <button class="diagnostics-modal-close" @click="goBack">✕</button>
      </div>
      <div class="diagnostics-modal-body" v-if="diagnostics">
        <div class="diag-sheet">
          <div class="diag-title">VEHICLE DIAGNOSTICS SHEET</div>
          <hr>
          <div><strong>Vehicle:</strong> {{ diagnostics.vehicleName }}</div>
          <div><strong>Mileage:</strong> {{ diagnostics.mileage.toLocaleString() }} mi</div>
          <div><strong>Overall Wear:</strong> {{ diagnostics.wear.toFixed(1) }}%</div>
          <div><strong>Needs Repair:</strong>
            <span :class="{ 'diag-bad': diagnostics.needsRepair, 'diag-good': !diagnostics.needsRepair }">
              {{ diagnostics.needsRepair ? 'YES' : 'NO' }}
            </span>
          </div>
          <hr>
          <div>
            <strong>Damaged/Low Condition Parts:</strong>
            <table class="diag-table">
              <tr>
                <th>Part</th>
                <th>Condition</th>
                <th>Status</th>
              </tr>
              <tr v-for="p in diagnostics.damagedParts" :key="p.name">
                <td>{{ p.name }}</td>
                <td>{{ p.percent }}%</td>
                <td>
                  <span :class="{
                    'diag-bad': p.percent <= 50,
                    'diag-warn': p.percent <= 80 && p.percent > 50,
                    'diag-good': p.percent > 80
                  }">
                    {{ p.percent > 80 ? 'Good' : (p.percent > 50 ? 'Worn' : 'Critical') }}
                  </span>
                </td>
              </tr>
              <tr v-if="diagnostics.damagedParts.length === 0">
                <td colspan="3" class="diag-good">No significant issues detected.</td>
              </tr>
            </table>
          </div>
          <hr>
          <div class="diag-timestamp">Report Generated: {{ timestamp }}</div>
        </div>
      </div>
      <div class="diagnostics-modal-footer">
        <button class="bng-button-outline" @click="goBack">Back</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue"
import { useRoute, useRouter } from "vue-router"
import { lua } from "@/bridge"

const route = useRoute()
const router = useRouter()
const diagnostics = ref(null)
const timestamp = ref(new Date().toLocaleString())

const goBack = () => router.back()

onMounted(async () => {
  // vehicleId passed via route param or state
  const vehicleId = route.params.vehicleId || route.query.vehicleId
  if (!vehicleId) {
    diagnostics.value = { error: "No vehicle selected", damagedParts: [] }
    return
  }
  // Call Lua: expects career_modules_inventory.getDiagnosticsReport(vehicleId)
  const result = await lua.career_modules_inventory.getDiagnosticsReport(Number(vehicleId))
  diagnostics.value = result
})
</script>

<style scoped>
.diagnostics-modal-bg {
  position: fixed; z-index: 99999; left: 0; top: 0; width: 100vw; height: 100vh;
  background: rgba(15,15,20,0.70); display: flex; align-items: center; justify-content: center;
}
.diagnostics-modal {
  background: #f5f5f2; color: #222; border-radius: 8px; width: 420px;
  box-shadow: 0 8px 38px #0005; padding: 0; display: flex; flex-direction: column;
  font-family: "Consolas", "Courier New", monospace;
  overflow: hidden;
  border: 2px solid #222;
}
.diagnostics-modal-header {
  font-weight: 700; background: #222; color: #fff; padding: 0.7em 1em; display: flex; justify-content: space-between; align-items: center;
}
.diagnostics-modal-close {
  background: none; border: none; color: #fff; font-size: 1.2em; cursor: pointer;
}
.diagnostics-modal-body {
  padding: 1em 1.5em 0.5em 1.5em; font-size: 1em;
}
.diagnostics-modal-footer {
  padding: 0.8em 1.5em; background: #eee; text-align: right; border-top: 1px solid #ccc;
}
.diag-sheet {
  background: #fff; border: 1px solid #bbb; padding: 1em;
  border-radius: 4px; margin-bottom: 1em;
  box-shadow: 0 1px 5px #0001;
}
.diag-title {
  font-size: 1.13em; text-align: center; letter-spacing: 0.1em; font-weight: bold; margin-bottom: 0.5em; color: #2e4071;
}
.diag-table {
  width: 100%; border-collapse: collapse; margin: 0.7em 0;
}
.diag-table th, .diag-table td {
  border: 1px solid #bbb; padding: 0.28em 0.6em; text-align: left;
}
.diag-bad    { color: #ea4545; font-weight: bold;}
.diag-warn   { color: #feb700; font-weight: bold;}
.diag-good   { color: #30a948; font-weight: bold;}
.diag-timestamp { font-size: 0.93em; color: #555; margin-top: 0.8em; text-align: right;}
.icon { margin-right: 6px; font-size: 1.1em; }
</style>