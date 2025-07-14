<script>
import { mapGetters } from 'vuex';
import { ref, watch, computed } from 'vue';
import { useEmitter } from 'dashboard/composables/emitter';
import {
  CMD_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import wootConstants from 'dashboard/constants/globals';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    CustomAttribute,
    Button,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contact: {
      type: Object,
      default: () => ({}),
    },
    chat: {
      type: Object,
      default: () => ({}),
    },
  },
  setup(props, { emit }) {
    const store = useStore();
    const isLoading = ref(false);
    const isModalVisible = ref(props.show);
    const { t } = useI18n();

    const currentChat = computed(() => {
      return store.getters.getSelectedChat;
    });

    const attributes = computed(() => {
      return store.getters['attributes/getAttributesByModel']('conversation_attribute');
    });

    const solutionAttributes = computed(() => {
      const solution = attributes.value.find(attribute => attribute.attribute_key === 'solution_list');
      const solutionText = attributes.value.find(attribute => attribute.attribute_key === 'solution');
      return { solution, solutionText };
    });

    const solutionAttribute = computed(() => solutionAttributes.value.solution);
    const solutionText = computed(() => solutionAttributes.value.solutionText);

    const customAttributes = computed(() => {
      return currentChat.value?.custom_attributes || {};
    });

    const toggleStatus = (status) => {
      isLoading.value = true;
      store.dispatch('toggleStatus', {
        conversationId: currentChat.value.id,
        status,
      }).then(() => {
        isLoading.value = false;
      });
    };

    const onCmdResolveConversation = () => {
      if (customAttributes.value[solutionAttribute.value.attribute_key] !== undefined) {
        const solutionKey = customAttributes.value[solutionAttribute.value.attribute_key];
        const solutionTextKey = customAttributes.value[solutionText.value.attribute_key];
        if (['não listada', 'not listed', 'no listada'].includes(solutionKey) && !solutionTextKey) {
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

    watch(() => props.show, (newVal) => {
      isModalVisible.value = newVal;
    });

    watch(isModalVisible, (newVal) => {
      emit('update:show', newVal);
    });

    return {
      isLoading,
      onCmdResolveConversation,
      onCancel,
      isModalVisible,
      currentChat,
      solutionAttribute,
      solutionText,
      customAttributes,
    };
  },
  computed: {
    ...mapGetters({
      attributes: 'attributes/getAttributesByModel',
    }),
    contactId() {
      return this.contact.id;
    },
    isOpen() {
      return this.currentChat?.status === wootConstants.STATUS_TYPE.OPEN;
    },
  },
  watch: {
    'contact.id'(id) {
      this.$store.dispatch('contacts/fetchContactableInbox', id);
    },
  },
  mounted() {
    const { id } = this.contact;
    this.$store.dispatch('contacts/fetchContactableInbox', id);
  },
  methods: {
    async onUpdate(key, value) {
      const updatedAttributes = { ...this.customAttributes, [key]: value };
      try {
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.currentChat.id,
          customAttributes: updatedAttributes,
        });
        useAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR');
        useAlert(errorMessage);
      }
    },
    async onDelete(key) {
      try {
        const { [key]: remove, ...updatedAttributes } = this.customAttributes;
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.currentChat.id,
          customAttributes: updatedAttributes,
        });
        useAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CUSTOM_ATTRIBUTES.FORM.DELETE.ERROR');
        useAlert(errorMessage);
      }
    },
    async onCopy(attributeValue) {
      await this.$copyTextToClipboard(attributeValue);
      useAlert(this.$t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
    },
    onSuccess() {
      useAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.UPDATE.SUCCESS'));
    },
  },
};
</script>

<template>
  <woot-modal :show.sync="isModalVisible" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('SOLUTION.TITLE')" :header-content="$t('SOLUTION.DESC')" />
      <CustomAttribute v-if="solutionAttribute" :key="solutionAttribute.id"
        :attribute-key="solutionAttribute.attribute_key" :attribute-type="solutionAttribute.attribute_display_type"
        :values="solutionAttribute.attribute_values" :label="solutionAttribute.attribute_display_name"
        :description="solutionAttribute.attribute_description"
        :value="customAttributes[solutionAttribute.attribute_key]" show-actions
        :attribute-regex="solutionAttribute.regex_pattern" :regex-cue="solutionAttribute.regex_cue"
        :contact-id="contactId" class="border-b border-solid border-slate-50 dark:border-slate-700/50 custom-attribute"
        @success="onSuccess" @cancel="onCancel" @update="onUpdate" @delete="onDelete" @copy="onCopy" />
      <CustomAttribute v-if="solutionText" :key="solutionText.id" :attribute-key="solutionText.attribute_key"
        :attribute-type="solutionText.attribute_display_type" :values="solutionText.attribute_values"
        :label="solutionText.attribute_display_name" :description="solutionText.attribute_description"
        :value="customAttributes[solutionText.attribute_key]" show-actions
        :attribute-regex="solutionText.regex_pattern" :regex-cue="solutionText.regex_cue" :contact-id="contactId"
        class="border-b border-solid border-slate-50 dark:border-slate-700/50 custom-attribute" @success="onSuccess"
        @cancel="onCancel" @update="onUpdate" @delete="onDelete" @copy="onCopy" />
      <div class="button-group">
        <Button
          v-if="isOpen"
          size="sm"
          color="teal"
          icon="i-lucide-check"
          class="!outline-0"
          :is-loading="isLoading"
          @click="onCmdResolveConversation"
        >{{ $t('CONVERSATION.HEADER.RESOLVE_ACTION') }}</Button>
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