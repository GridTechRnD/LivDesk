<script setup>
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import { computed } from 'vue';

const emit = defineEmits(['close', 'submit', 'update:responsavelDelecao']);
const props = defineProps({
  show: Boolean,
  deleteItem: Object,
  responsavelDelecao: String,
  isSubmitting: Boolean,
  submitError: String,
  agents: Array
});

const selectedAgentName = computed(() => {
  const found = (props.agents || []).find(agent => String(agent.id) === String(props.responsavelDelecao));
  return found ? found.name : '';
});

function onAgentUpdateWithEvent(key, value, event) {
  if (event && typeof event.preventDefault === 'function') event.preventDefault();
  if (event && typeof event.stopPropagation === 'function') event.stopPropagation();
  const found = (props.agents || []).find(agent => agent.name === value);
  if (found) {
    emit('update:responsavelDelecao', String(found.id));
  } else {
    emit('update:responsavelDelecao', '');
  }
}
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
    <div class="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-6 w-full max-w-md">
      <h2 class="text-xl font-semibold mb-4 text-slate-900 dark:text-slate-100">Excluir disponibilidade</h2>
      <p class="mb-4">Tem certeza que deseja excluir o registro <b>#{{ deleteItem && deleteItem.id }}</b>? Informe o responsável pela exclusão para confirmar.</p>
      <CustomAttribute
        attribute-key="responsavelDelecao"
        attribute-type="list"
        :values="(agents || []).map(agent => agent.name)"
        :label="'Responsável pela exclusão'"
        :description="'Selecione o responsável pela exclusão'"
        :value="selectedAgentName"
        @update="onAgentUpdateWithEvent"
        @click.prevent
        required
        :class="'w-full !p-0 mb-4'"
      />
      <div v-if="submitError" class="mb-2 text-red-500 text-sm">{{ submitError }}</div>
      <div class="flex justify-end gap-2">
        <button type="button" @click="$emit('close')" class="px-4 py-2 rounded bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100">Cancelar</button>
        <button type="button" :disabled="isSubmitting || !responsavelDelecao" @click="$emit('submit')" class="px-4 py-2 rounded bg-red-500 hover:bg-red-600 text-white font-medium">
          <span v-if="isSubmitting">Excluindo...</span>
          <span v-else>Excluir</span>
        </button>
      </div>
    </div>
  </div>
</template>
