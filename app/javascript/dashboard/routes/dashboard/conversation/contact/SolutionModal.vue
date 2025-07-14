
<script setup>
import { ref, watch, computed } from 'vue';
import { useEmitter } from 'dashboard/composables/emitter';
import { CMD_RESOLVE_CONVERSATION } from 'dashboard/helper/commandbar/events';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import wootConstants from 'dashboard/constants/globals';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { defineEmits } from 'vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['success', 'update:show', 'cancel']);

const store = useStore();
const isLoading = ref(false);
const isModalVisible = ref(props.show);
const { t } = useI18n();

const currentChat = computed(() => store.getters.getSelectedChat);
const contactId = computed(() => props.contact.id);
const isOpen = computed(() =>
  currentChat.value?.status === wootConstants.STATUS_TYPE.OPEN
);

const attributes = computed(() =>
  store.getters['attributes/getAttributesByModel']('conversation_attribute')
);

const solutionAttributes = computed(() => {
  const solution = attributes.value.find(
    attribute => attribute.attribute_key === 'solution_list',
  );
  const solutionText = attributes.value.find(
    attribute => attribute.attribute_key === 'solution',
  );
  return { solution, solutionText };
});

const solutionAttribute = computed(() => solutionAttributes.value.solution);
const solutionText = computed(() => solutionAttributes.value.solutionText);

const customAttributes = computed(() =>
  currentChat.value?.custom_attributes || {}
);

const toggleStatus = status => {
  isLoading.value = true;
  store
    .dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status
    })
    .then(() => {
      isLoading.value = false;
    });
};

const onCmdResolveConversation = () => {
  if (
    customAttributes.value[solutionAttribute.value?.attribute_key] !== undefined
  ) {
    const solutionKey = customAttributes.value[solutionAttribute.value.attribute_key];
    const solutionTextKey = customAttributes.value[solutionText.value.attribute_key];
    if (
      ['não listada', 'not listed', 'no listada'].includes(solutionKey) &&
      !solutionTextKey
    ) {
      useAlert(t('SOLUTION.EMPTY_OTHER_ALERT'));
      return;
    }
    toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
    isModalVisible.value = false;
    emit('success');
    useAlert(t('SOLUTION.SUCCESS_ALERT'));
  } else {
    useAlert(t('SOLUTION.EMPTY_VALUES_ALERT'));
  }
};

const onSubmitSolution = () => {
  toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
};

useEmitter(CMD_RESOLVE_CONVERSATION, onSubmitSolution);

const onCancel = () => {
  isModalVisible.value = false;
  emit('update:show', false);
  emit('cancel');
};

watch(
  () => props.show,
  newVal => {
    isModalVisible.value = newVal;
  }
);

watch(isModalVisible, newVal => {
  emit('update:show', newVal);
});

watch(
  () => props.contact.id,
  id => {
    store.dispatch('contacts/fetchContactableInbox', id);
  }
);

const onUpdate = async (key, value) => {
  const updatedAttributes = { ...customAttributes.value, [key]: value };
  try {
    await store.dispatch('updateCustomAttributes', {
      conversationId: currentChat.value.id,
      customAttributes: updatedAttributes,
    });
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const onDelete = async key => {
  try {
    const { [key]: remove, ...updatedAttributes } = customAttributes.value;
    await store.dispatch('updateCustomAttributes', {
      conversationId: currentChat.value.id,
      customAttributes: updatedAttributes,
    });
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

const onCopy = async attributeValue => {
  await navigator.clipboard.writeText(attributeValue);
  useAlert(t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
};

const onSuccess = () => {
  useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
};

// Fetch contactable inbox on mount
store.dispatch('contacts/fetchContactableInbox', props.contact.id);
</script>

<template>
  <woot-modal v-model:show="isModalVisible" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="t('SOLUTION.TITLE')"
        :header-content="t('SOLUTION.DESC')"
      />
      <CustomAttribute
        v-if="solutionAttribute"
        :key="solutionAttribute.id"
        :attribute-key="solutionAttribute.attribute_key"
        :attribute-type="solutionAttribute.attribute_display_type"
        :values="solutionAttribute.attribute_values"
        :label="solutionAttribute.attribute_display_name"
        :description="solutionAttribute.attribute_description"
        :value="customAttributes[solutionAttribute.attribute_key]"
        show-actions
        :attribute-regex="solutionAttribute.regex_pattern"
        :regex-cue="solutionAttribute.regex_cue"
        :contact-id="contactId"
        class="border-b border-solid border-slate-50 dark:border-slate-700/50 custom-attribute"
        @success="onSuccess"
        @cancel="onCancel"
        @update="onUpdate"
        @delete="onDelete"
        @copy="onCopy"
      />
      <CustomAttribute
        v-if="solutionText"
        :key="solutionText.id"
        :attribute-key="solutionText.attribute_key"
        :attribute-type="solutionText.attribute_display_type"
        :values="solutionText.attribute_values"
        :label="solutionText.attribute_display_name"
        :description="solutionText.attribute_description"
        :value="customAttributes[solutionText.attribute_key]"
        show-actions
        :attribute-regex="solutionText.regex_pattern"
        :regex-cue="solutionText.regex_cue"
        :contact-id="contactId"
        class="border-b border-solid border-slate-50 dark:border-slate-700/50 custom-attribute"
        @success="onSuccess"
        @cancel="onCancel"
        @update="onUpdate"
        @delete="onDelete"
        @copy="onCopy"
      />
      <div class="button-group">
        <Button
          v-if="isOpen"
          size="sm"
          color="teal"
          icon="i-lucide-check"
          class="!outline-0"
          :is-loading="isLoading"
          @click="onCmdResolveConversation"
        >
          {{ t('CONVERSATION.HEADER.RESOLVE_ACTION') }}
        </Button>
      </div>
    </div>
  </woot-modal>
</template>

<style lang="scss" scoped>
.button-group {
  display: flex;
  justify-content: flex-end;
  margin: 1rem;
}

.custom-attribute {
  padding-left: 1rem;
}

.border-b {
  padding-left: 2.3rem !important;
}

.woot-modal-header {
  padding-left: 1.5rem !important;
  padding-bottom: 1rem !important;
}
</style>