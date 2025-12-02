<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
  agents: {
    type: Array,
    default: () => [],
  },
  inboxes: {
    type: Array,
    default: () => [],
  },
  motivoOptions: {
    type: Array,
    default: () => [],
  },
});
defineEmits(['edit', 'delete']);
const { t } = useI18n();

function getAgentName(id) {
  const found = props.agents.find(agent => String(agent.id) === String(id));
  return found ? found.name : id || '-';
}
function getInboxName(id) {
  const found = props.inboxes.find(inbox => String(inbox.id) === String(id));
  return found ? found.name : id || '-';
}
function getMotivoLabel(value) {
  const found = props.motivoOptions.find(opt => opt.value === value);
  if (found) return t(found.label);
  return t('AVAILABILITY.MOTIVO.' + value) || value || '-';
}

function formatDateTime(dt) {
  if (!dt) return '-';
  const date = typeof dt === 'string' ? new Date(dt) : dt;
  if (isNaN(date)) return dt;
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).format(date);
}
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4 truncate">{{ item.id }}</td>
  <td class="py-4 ltr:pr-4 rtl:pl-4">{{ formatDateTime(item.inicio) }}</td>
  <td class="py-4 ltr:pr-4 rtl:pl-4">{{ formatDateTime(item.fim) }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ getMotivoLabel(item.motivo) }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ getInboxName(item.inbox_id) }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ getAgentName(item.responsavel) }}</td>
    <td class="py-4 flex justify-end gap-1">
      <Button
        icon="i-lucide-pen"
        slate
        xs
        faded
        @click="$emit('edit')"
      />
      <Button
        icon="i-lucide-trash-2"
        xs
        ruby
        faded
        @click="$emit('delete')"
      />
    </td>
  </tr>
</template>
