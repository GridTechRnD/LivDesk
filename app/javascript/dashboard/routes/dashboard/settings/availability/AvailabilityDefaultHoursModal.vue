<script setup>
import { onMounted, ref, watch } from 'vue';
import TimePicker from '../../../../components/ui/TimePicker.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['close']);
const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
  submitError: {
    type: String,
    default: '',
  },
});

const defaultHours = ref([]);

const fetchDefaultHours = async () => {
  try {
    const response = await fetch('https://automacao.livoltek.com.br/webhook/default_hours');
    if (!response.ok) throw new Error('Network response was not ok');
    const data = await response.json();
    defaultHours.value = Array.isArray(data) ? data : [];
  } catch (err) {
    console.error('Error fetching default hours in modal:', err);
    defaultHours.value = [];
  }
};

const isSubmitting = ref(false);
const submitError = ref('');

const toTimeString = date => {
  if (!date) return null;
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
};

const onSave = async () => {
  submitError.value = '';
  for (const row of localHours.value || []) {
    if (!row.inicio || !row.fim) {
      submitError.value = $t('AVAILABILITY.DEFAULT_HOURS.ERRORS.FILL_ALL');
      return;
    }
    if (row.fim <= row.inicio) {
      submitError.value = $t('AVAILABILITY.DEFAULT_HOURS.ERRORS.START_LESS_THAN_END');
      return;
    }
  }
  isSubmitting.value = true;
  try {
    for (const row of localHours.value || []) {
      const payload = {
        ...row,
        inicio: toTimeString(row.inicio),
        fim: toTimeString(row.fim),
      };
      const response = await fetch('https://automacao.livoltek.com.br/webhook/update_default_hours', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!response.ok) throw new Error('Network response was not ok');
    }
    await fetchDefaultHours();
    emit('close');
  } catch (err) {
    submitError.value = err.message;
  } finally {
    isSubmitting.value = false;
  }
};

const localHours = ref([]);

const syncLocalHours = () => {
  localHours.value = (defaultHours.value || []).map(item => ({
    chave: item.chave,
    inicio: timeStringToDate(item.inicio),
    fim: timeStringToDate(item.fim),
  }));
};

onMounted(async () => {
  await fetchDefaultHours();
  syncLocalHours();
});

const onClose = () => {
  emit('close');
};

const onUpdateShow = (val) => {
  if (!val) emit('close');
};

const timeStringToDate = (timeStr) => {
  if (!timeStr) return null;
  const [hours, minutes, seconds = '00'] = timeStr.split(':');
  const date = new Date();
  date.setHours(Number(hours), Number(minutes), Number(seconds), 0);
  return date;
};

const onTimeInicioChange = (idx, date) => {
  localHours.value[idx].inicio = date;
};

const onTimeFimChange = (idx, date) => {
  localHours.value[idx].fim = date;
};

onMounted(() => {
  const arr = props.defaultHours && typeof props.defaultHours === 'object' && 'value' in props.defaultHours
    ? props.defaultHours.value
    : props.defaultHours;
});

</script>

<template>
  <woot-modal :show="show" @update:show="onUpdateShow" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('AVAILABILITY.DEFAULT_HOURS.TITLE')"
        :header-content="$t('AVAILABILITY.DEFAULT_HOURS.DESC')"
      />
      <table class="min-w-full divide-y divide-slate-75 dark:divide-slate-700 mt-4">
        <thead>
          <tr>
            <th class="py-2 px-4 text-left"></th>
            <th class="py-2 px-4 text-left">{{ $t('AVAILABILITY.DEFAULT_HOURS.INICIO') }}</th>
            <th class="py-2 px-4 text-left">{{ $t('AVAILABILITY.DEFAULT_HOURS.FIM') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, idx) in localHours" :key="row.chave">
            <td class="py-2 px-4">
              <span v-if="row.chave === 'almoco'">
                {{ $t('AVAILABILITY.DEFAULT_HOURS.ALMOCO') }}
              </span>
              <span v-else-if="row.chave === 'default'">
                {{ $t('AVAILABILITY.DEFAULT_HOURS.EXPEDIENTE') }}
              </span>
            </td>
            <td class="py-2 px-4">
              <TimePicker
                :value="row.inicio"
                @change="val => onTimeInicioChange(idx, val)"
                :placeholder="$t('AVAILABILITY.DEFAULT_HOURS.INICIO_PLACEHOLDER')"
                confirm
                :clearable="true"
                :editable="true"
                :confirm-text="$t('AVAILABILITY.DEFAULT_HOURS.SAVE')"
              />
            </td>
            <td class="py-2 px-4">
              <TimePicker
                :value="row.fim"
                @change="val => onTimeFimChange(idx, val)"
                :placeholder="$t('AVAILABILITY.DEFAULT_HOURS.FIM_PLACEHOLDER')"
                confirm
                :clearable="true"
                :editable="true"
                :confirm-text="$t('AVAILABILITY.DEFAULT_HOURS.SAVE')"
              />
            </td>
          </tr>
        </tbody>
      </table>
      <div v-if="submitError || $props.submitError" class="text-red-500 text-sm my-2">{{ submitError || $props.submitError }}</div>
      <div class="flex justify-end mt-4 gap-2 pr-4 pb-4">
        <Button type="button" color="ruby" @click="emit('close')">
          {{ $t('AVAILABILITY.DEFAULT_HOURS.CANCEL') }}
        </Button>
        <Button
          color="teal"
          :is-loading="isSubmitting"
          :disabled="isSubmitting"
          @click="onSave"
        >
          {{ isSubmitting ? $t('AVAILABILITY.DEFAULT_HOURS.SAVING') : $t('AVAILABILITY.DEFAULT_HOURS.SAVE') }}
        </Button>
      </div>
    </div>
  </woot-modal>
</template>
