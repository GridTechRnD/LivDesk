<script setup>
import DateTimePicker from '../../../../components/ui/DateTimePicker.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import { computed } from 'vue';

const emit = defineEmits(['close', 'submit']);
const props = defineProps({
  show: Boolean,
  form: {
    type: Object,
    default: () => ({
      inicio: null,
      fim: null,
      motivo: '',
      mensagem: '',
      responsavel: '',
      account_id: '',
      inbox_id: '',
    })
  },
  inboxes: Array,
  motivoOptions: Array,
  agents: Array,
  isSubmitting: Boolean,
  submitError: String
});

const selectedAgentName = computed(() => {
  const found = props.agents.find(agent => String(agent.id) === String(props.form.responsavel));
  return found ? found.name : '';
});

function onAgentUpdateWithEvent(key, value, event) {
  if (event && typeof event.preventDefault === 'function') event.preventDefault();
  if (event && typeof event.stopPropagation === 'function') event.stopPropagation();
  const found = props.agents.find(agent => agent.name === value);
  if (found) {
    props.form[key] = String(found.id);
  } else {
    props.form[key] = '';
  }
}

const selectedInboxName = computed(() => {
  const found = props.inboxes.find(inbox => String(inbox.id) === String(props.form.inbox_id));
  return found ? found.name : '';
});

function onInboxUpdateWithEvent(key, value, event) {
  if (event && typeof event.preventDefault === 'function') event.preventDefault();
  if (event && typeof event.stopPropagation === 'function') event.stopPropagation();
  const found = props.inboxes.find(inbox => inbox.name === value);
  if (found) {
    props.form[key] = String(found.id);
  } else {
    props.form[key] = '';
  }
}


const onClose = () => {
  emit('close');
};

const onUpdateShow = (val) => {
  if (!val) emit('close');
};
</script>
<template>
  <woot-modal :show="show" @update:show="onUpdateShow" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('AVAILABILITY.MODAL.TITLE')"
        :header-content="$t('AVAILABILITY.MODAL.DESC')"
      />
      <form @submit.prevent="$emit('submit')" @keydown.enter.prevent class="px-4 pb-2">
        <input type="hidden" :value="form.who_created" name="who_created" />
        <div class="mb-3">
          <CustomAttribute
            attribute-key="responsavel"
            attribute-type="list"
            :values="agents.map(agent => agent.name)"
            :label="$t('AVAILABILITY.FORM.RESPONSAVEL')"
            :description="$t('AVAILABILITY.FORM.RESPONSAVEL_PLACEHOLDER')"
            :value="selectedAgentName"
            @update="onAgentUpdateWithEvent"
            @click.prevent
            required
            :class="'w-full !p-0'"
          />
        </div>
        <div class="mb-3">
          <CustomAttribute
            attribute-key="inbox_id"
            attribute-type="list"
            :values="inboxes.map(inbox => inbox.name)"
            :label="$t('AVAILABILITY.FORM.INBOX')"
            :description="$t('AVAILABILITY.FORM.INBOX_PLACEHOLDER')"
            :value="selectedInboxName"
            @update="onInboxUpdateWithEvent"
            @click.prevent
            required
            :class="'w-full !p-0'"
          />
        </div>
        <div class="mb-3 flex flex-col sm:flex-row gap-2">
          <div class="flex-1">
            <label class="block text-sm font-medium mb-1" for="inicio">{{ $t('AVAILABILITY.FORM.INICIO') }}</label>
            <DateTimePicker
              :value="form.inicio"
              @change="form.inicio = $event"
              id="inicio"
              :placeholder="$t('AVAILABILITY.FORM.INICIO_PLACEHOLDER')"
              confirm
              :clearable="true"
              :editable="true"
              :confirm-text="$t('AVAILABILITY.FORM.SAVE')"
            />
          </div>
          <div class="flex-1">
            <label class="block text-sm font-medium mb-1" for="fim">{{ $t('AVAILABILITY.FORM.FIM') }}</label>
            <DateTimePicker
              :value="form.fim"
              @change="form.fim = $event"
              id="fim"
              :placeholder="$t('AVAILABILITY.FORM.FIM_PLACEHOLDER')"
              confirm
              :clearable="true"
              :editable="true"
              :confirm-text="$t('AVAILABILITY.FORM.SAVE')"
            />
          </div>
        </div>
        <div class="mb-3">
          <CustomAttribute
            attribute-key="motivo"
            attribute-type="list"
            :values="motivoOptions.map(opt => $t(opt.label))"
            :label="$t('AVAILABILITY.FORM.MOTIVO')"
            :description="$t('AVAILABILITY.FORM.MOTIVO_PLACEHOLDER')"
            :value="motivoOptions.find(opt => opt.value === form.motivo) ? $t(motivoOptions.find(opt => opt.value === form.motivo).label) : ''"
            @update="(key, value, event) => {
              if (event && typeof event.preventDefault === 'function') event.preventDefault();
              if (event && typeof event.stopPropagation === 'function') event.stopPropagation();
              const found = motivoOptions.find(opt => $t(opt.label) === value);
              form[key] = found ? found.value : '';
            }"
            @click.prevent
            required
            :class="'w-full !p-0'"
          />
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium mb-1" for="mensagem">{{ $t('AVAILABILITY.FORM.MENSAGEM') }}</label>
          <textarea v-model="form.mensagem" id="mensagem" class="w-full px-3 py-2 border rounded" required :placeholder="$t('AVAILABILITY.FORM.MENSAGEM_PLACEHOLDER')"></textarea>
        </div>
        <div v-if="submitError" class="mb-2 text-red-500 text-sm">{{ submitError }}</div>
        <div class="button-group flex justify-end gap-2 mt-4">
          <Button type="button" color="ruby" @click="$emit('close')">
            {{ $t('AVAILABILITY.FORM.CANCEL') }}
          </Button>
          <Button type="submit" color="teal" :is-loading="isSubmitting">
            {{ isSubmitting ? $t('AVAILABILITY.FORM.SAVING') : $t('AVAILABILITY.FORM.SAVE') }}
          </Button>
        </div>
      </form>
    </div>
  </woot-modal>
</template>
