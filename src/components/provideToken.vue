<script setup lang="ts">
  import { ref, type Ref } from 'vue';
  import { useCookies } from '@vueuse/integrations/useCookies';

  const cookies = useCookies(['token'])
  const input: Ref<HTMLInputElement| null>= ref(null)
  function setToken() {
    if (input.value && input.value.value != '') cookies.set('token', input.value.value, { expires: new Date("9999") })
    window.location.reload();
  }
</script>

<template>
  <div class="main">
    <div class="box">
      <div class="content">
        <input ref="input" type="password" placeholder="Input your bot token...">
        <button @click="setToken()">Set Token</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
  .main {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: calc(100vh - 1vw);
  }

  .box {
    border-radius: 1em;
    background-color: var(--light-color);
  }

  .content {
    margin: 1em;
    display: flex;
    gap: 1em;
  }
</style>