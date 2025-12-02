<script setup>
import { ref, onMounted, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import AvailabilityTableRow from './AvailabilityTableRow.vue';
import AvailabilityFormModal from './AvailabilityFormModal.vue';
import AvailabilityDefaultHoursModal from './AvailabilityDefaultHoursModal.vue';
import AvailabilityDeleteModal from './AvailabilityDeleteModal.vue';

import InboxesAPI from 'dashboard/api/inboxes';
import AgentsAPI from 'dashboard/api/agents';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

  const availabilityList = ref([]);
  const isLoading = ref(true);
  const error = ref(null);
  const showModal = ref(false);
  const showDefaultHoursModal = ref(false);
  const showDeleteModal = ref(false);
  const editingItem = ref(null);
  const deleteItem = ref(null);
  const responsavelDelecao = ref('');
  const motivoOptions = [
    { value: 'RECESS', label: 'AVAILABILITY.MOTIVO.RECESS' },
    { value: 'UNAVAILABILITY', label: 'AVAILABILITY.MOTIVO.UNAVAILABILITY' },
    { value: 'MAINTENANCE', label: 'AVAILABILITY.MOTIVO.MAINTENANCE' }
  ];
  const inboxes = ref([]);
  const agents = ref([]);
  const accountIdFromUrl = (() => {
    const match = window.location.pathname.match(/\/accounts\/(\d+)/);
    return match ? match[1] : '';
  })();
  const currentUser = useMapGetter('getCurrentUser');
  const form = ref({
    inicio: null,
    fim: null,
    motivo: '',
    mensagem: '',
    responsavel: '',
    account_id: accountIdFromUrl,
    inbox_id: '',
    who_created: currentUser.value?.id || '',
  });

  const defaultHours = ref([]);
  const isSubmitting = ref(false);
  const submitError = ref(null);

  const tableHeaders = computed(() => [
    t('AVAILABILITY.LIST.TABLE_HEADER.ID'),
    t('AVAILABILITY.LIST.TABLE_HEADER.INICIO'),
    t('AVAILABILITY.LIST.TABLE_HEADER.FIM'),
    t('AVAILABILITY.LIST.TABLE_HEADER.MOTIVO'),
    // t('AVAILABILITY.LIST.TABLE_HEADER.MENSAGEM'),
    t('AVAILABILITY.LIST.TABLE_HEADER.INBOX'),
    t('AVAILABILITY.LIST.TABLE_HEADER.RESPONSAVEL'),
    t('AVAILABILITY.LIST.TABLE_HEADER.ACOES'),
  ]);

  const fetchDefaultHours = async () => {
    try {
      const response = await fetch('https://automacao.livoltek.com.br/webhook/default_hours');
      if (!response.ok) throw new Error('Network response was not ok');
      const data = await response.json();
      if (Array.isArray(data)) {
        defaultHours.value = data;
      } else {
        defaultHours.value = [];
      }
    } catch (err) {
      console.error('Error fetching default hours:', err);
    }
  };

  const fetchData = async () => {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await fetch('https://automacao.livoltek.com.br/webhook/unavailability');
      if (!response.ok) throw new Error('Network response was not ok');
      const data = await response.json();

      if (Array.isArray(data)) {
        availabilityList.value = data.filter(item => item && Object.keys(item).length > 0);
      } else if (data && typeof data === 'object' && Object.keys(data).length > 0) {
        availabilityList.value = [data];
      } else {
        availabilityList.value = [];
      }
    } catch (err) {
      error.value = err.message;
    } finally {
      isLoading.value = false;
    }
  };

  const fetchInboxes = async () => {
    if (!form.value.account_id) return;
    try {
      const { data } = await InboxesAPI.get();
      inboxes.value = Array.isArray(data.payload) ? data.payload : [];
    } catch (e) {
      inboxes.value = [];
    }
  };

  const fetchAgents = async () => {
    try {
      const { data } = await AgentsAPI.get();
      agents.value = Array.isArray(data) ? data : [];
    } catch (e) {
      agents.value = [];
    }
  };

  const openDefaultHoursModal = async () => {
    if (!defaultHours.value.length) {
      await fetchDefaultHours();
    }
    showDefaultHoursModal.value = true;
  };
  
  const closeDefaultHoursModal = () => {
    showDefaultHoursModal.value = false;
  };
  
  const openModal = (item = null) => {
    if (item) {
      editingItem.value = item;
      form.value.inicio = item.inicio ? new Date(item.inicio) : null;
      form.value.fim = item.fim ? new Date(item.fim) : null;
      form.value.motivo = item.motivo ?? '';
      form.value.mensagem = item.mensagem ?? '';
      form.value.responsavel = item.responsavel ?? '';
      form.value.account_id = accountIdFromUrl;
      form.value.inbox_id = item.inbox_id !== undefined && item.inbox_id !== null ? String(item.inbox_id) : '';
    } else {
      editingItem.value = null;
      form.value.inicio = null;
      form.value.fim = null;
      form.value.motivo = '';
      form.value.mensagem = '';
      form.value.responsavel = '';
      form.value.account_id = accountIdFromUrl;
      form.value.inbox_id = '';
      form.value.who_created = currentUser.value?.id || '';
    }
    submitError.value = null;
    showModal.value = true;
    fetchInboxes();
    fetchAgents();
  };
  
  const closeModal = () => {
    showModal.value = false;
    editingItem.value = null;
  };
  
  const openDeleteModal = (item) => {
    deleteItem.value = item;
    responsavelDelecao.value = '';
    showDeleteModal.value = true;
  };
  
  const closeDeleteModal = () => {
    showDeleteModal.value = false;
    deleteItem.value = null;
    responsavelDelecao.value = '';
  };
  
  const submitForm = async () => {
    isSubmitting.value = true;
    submitError.value = null;
    if (!form.value.inicio || !form.value.fim || isNaN(new Date(form.value.inicio)) || isNaN(new Date(form.value.fim))) {
      submitError.value = t('AVAILABILITY.FORM.ERRORS.INVALID_DATES');
      isSubmitting.value = false;
      return;
    }
    if (new Date(form.value.fim) <= new Date(form.value.inicio)) {
      submitError.value = t('AVAILABILITY.FORM.ERRORS.END_AFTER_START');
      isSubmitting.value = false;
      return;
    }
    if (!motivoOptions.some(opt => opt.value === form.value.motivo)) {
      submitError.value = t('AVAILABILITY.FORM.ERRORS.INVALID_REASON');
      isSubmitting.value = false;
      return;
    }
    if (!form.value.responsavel || form.value.responsavel.trim() === '') {
      submitError.value = t('AVAILABILITY.FORM.RESPONSAVEL_PLACEHOLDER');
      isSubmitting.value = false;
      return;
    }
    if (!form.value.mensagem || form.value.mensagem.trim() === '') {
      submitError.value = t('AVAILABILITY.FORM.ERRORS.MESSAGE_REQUIRED');
      isSubmitting.value = false;
      return;
    }
    form.value.account_id = accountIdFromUrl;
    if (!form.value.account_id || !form.value.inbox_id) {
      submitError.value = t('AVAILABILITY.FORM.ERRORS.ACCOUNT_INBOX_REQUIRED');
      isSubmitting.value = false;
      return;
    }
    const payload = {
      ...form.value,
      inicio: new Date(form.value.inicio).toISOString(),
      fim: new Date(form.value.fim).toISOString(),
      who_created: currentUser.value?.id || '',
    };
    try {
      let url = 'https://automacao.livoltek.com.br/webhook/create_scheduling';
      let method = 'POST';
      if (editingItem.value && editingItem.value.id) {
        url = 'https://automacao.livoltek.com.br/webhook/update_scheduling';
        method = 'PUT';
        payload.id = editingItem.value.id;
      }
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!response.ok) throw new Error('Network response was not ok');
      await fetchData();
      closeModal();
    } catch (err) {
      submitError.value = err.message;
    } finally {
      isSubmitting.value = false;
    }
  };
  
  

  
  const submitDelete = async () => {
    if (!deleteItem.value || !responsavelDelecao.value) return;
    isSubmitting.value = true;
    try {
      const response = await fetch('https://automacao.livoltek.com.br/webhook/delete_scheduling', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: deleteItem.value.id, responsavel_delecao: responsavelDelecao.value }),
      });
      if (!response.ok) throw new Error('Network response was not ok');
      await fetchData();
      closeDeleteModal();
    } catch (err) {
      submitError.value = err.message;
    } finally {
      isSubmitting.value = false;
    }
  };

  onMounted(() => {
    fetchData();
    fetchDefaultHours();
    fetchInboxes();
    fetchAgents();
  });
  </script>

  <template>
    <SettingsLayout
      :is-loading="isLoading"
      :loading-message="t('AVAILABILITY.LOADING')"
      feature-name="availability"
    >
      <template #header>
        <div class="px-6 sm:px-8 md:px-12 lg:px-16 xl:px-20 2xl:px-32 w-full mt-8">
          <BaseSettingsHeader
            :title="t('AVAILABILITY.HEADER')"
            :description="t('AVAILABILITY.DESCRIPTION')"
            :link-text="t('AVAILABILITY.LEARN_MORE')"
            feature-name="availability"
          >
            <template #actions>
              <Button
                class="ml-2"
                color="amber"
                icon="i-lucide-clock"
                :label="t('AVAILABILITY.DEFAULT_HOURS_BTN')"
                @click="openDefaultHoursModal"
              />
              <Button
                icon="i-lucide-circle-plus"
                :label="t('AVAILABILITY.HEADER_BTN_TXT')"
                @click="openModal"
              />
            </template>
          </BaseSettingsHeader>
        </div>
      </template>
      <template #body>
        <div class="px-6 sm:px-8 md:px-12 lg:px-16 xl:px-20 2xl:px-32 w-full mt-8">
          <table class="min-w-full divide-y divide-slate-75 dark:divide-slate-700">
            <thead>
              <tr>
                <th
                  v-for="header in tableHeaders"
                  :key="header"
                  class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                >
                  {{ header }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-weak text-n-slate-11">
              <AvailabilityTableRow
                v-for="item in availabilityList"
                :key="item.id"
                :item="item"
                :agents="agents"
                :inboxes="inboxes"
                @edit="openModal(item)"
                @delete="openDeleteModal(item)"
              />
              <tr v-if="availabilityList.length === 0">
                <td :colspan="tableHeaders.length" class="text-center text-slate-500 py-6">
                  {{ t('AVAILABILITY.LIST.404') }}
                </td>
              </tr>
            </tbody>
          </table>
          <AvailabilityFormModal
            :show="showModal"
            :form="form"
            :inboxes="inboxes"
            :motivoOptions="motivoOptions"
            :agents="agents"
            :isSubmitting="isSubmitting"
            :submitError="submitError"
            @close="closeModal"
            @submit="submitForm"
          />  
          <AvailabilityDefaultHoursModal
            :show="showDefaultHoursModal"
            @close="closeDefaultHoursModal"
          />
          <AvailabilityDeleteModal
            :show="showDeleteModal"
            :deleteItem="deleteItem"
            :agents="agents"
            v-model:responsavelDelecao="responsavelDelecao"
            :isSubmitting="isSubmitting"
            :submitError="submitError"
            @close="closeDeleteModal"
            @submit="submitDelete"
          />
        </div>
      </template>
    </SettingsLayout>
  </template>
