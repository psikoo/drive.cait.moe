<script setup lang="ts">
  const props = defineProps<{
    channels: any;
    channelId: any;
    loading: boolean;
  }>()
</script>

<template>
  <div class="sidebar">
    <div class="grow">
      <div class="channels" v-if="loading == false">
        <div v-for="(channel) in channels" :class="{ selected: channel.id==channelId, channel: true }">
          <button @click="$emit('changeChannel', channel.id)">
            > {{ channel.name }}
          </button>
        </div>
      </div>
    </div>
    <div class="add">
      <button @click="$emit('update', [ false, false, true, true ])">
        <p>Reload Channels</p>
      </button>
    </div>
  </div>
</template>

<style scoped>
  .sidebar {
    width: 15%;
    min-width: 15%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: stretch;
    background-color: var(--mid-color) !important;
    border-radius: 0 0 0 1em;
    border-right: 1px solid var(--border-color);
  }
  
  .channels {
    padding: 0.5em;
    max-height: 85vh;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    align-items: stretch;
    gap: 0.5em;
  }

  .channel>button {
    text-align: left;
    width: 100%;
    background-color: var(--dark-color) !important;
  }

  .add>button {
    width: 100%;
    border-radius: 0 0 0 1em;
  }

  .grow {
    flex: 1;
  }

  .selected>button {
    background-color: var(--light-color) !important;
  }
</style>