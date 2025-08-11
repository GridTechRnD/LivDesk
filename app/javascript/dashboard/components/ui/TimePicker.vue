<script>
import DatePicker from 'vue-datepicker-next';
export default {
  components: { DatePicker },
  props: {
    confirmText: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
    value: {
      type: Date,
      default: null,
    },
    clearable: {
      type: Boolean,
      default: false,
    },
    editable: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['change'],
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <div class="time-picker">
    <DatePicker
      type="time"
      confirm
      :clearable="clearable"
      :editable="editable"
      :confirm-text="confirmText"
      :placeholder="placeholder"
      :value="value"
      @change="handleChange"
    />
  </div>
</template>
