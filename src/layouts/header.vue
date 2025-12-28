<script setup lang="ts">
  import { useCookies } from '@vueuse/integrations/useCookies';
  const cookies = useCookies(['token']);

  const props = defineProps<{
    bot: any;
    guilds: any;
    loading: boolean;
  }>()

  function logout() {
    cookies.remove('token');
    window.location.reload();
  }
</script>

<template>
  <img src="/icon.png" alt="drive">
  <h1>Cait Drive</h1>
  <div class="grow">
    <div class="info" v-if="loading == false">
      <h2>Bot: {{ bot.username }}</h2>
      <h2>Server: {{ guilds[0].name }} ({{ guilds[0].id }})</h2> 
    </div>
  </div>
  <button @click="logout()">
    <h2>Logout</h2>
  </button>
</template>

<style scoped>
  .info {
    display: flex;
    gap: 1em;
    justify-content: center;
    align-items: center;
  }

  .grow {
    flex-grow: 1;
  }
</style>