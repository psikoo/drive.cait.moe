<script setup lang="ts">
  const props = defineProps<{
    active: boolean;
    color: 'green' | 'red';
    chunkTotal: number;
    chunkCurrent: number;
  }>()
  function checkChunk(chunkCurrent: number, index: number, color: 'green' | 'red'): boolean {
    return (chunkCurrent >= index) && props.color == color;
  }
</script>

<template>
  <div class="progress" v-if="active">
    <div class="grow bar">
      <div v-for="index in chunkTotal" :key="index" class="grow">
        <div v-if="index == 1" :class="{ doneU: checkChunk(chunkCurrent, index, 'green'), doneD: checkChunk(chunkCurrent, index, 'red'), chunkLeft: true }">{{ index }}</div>
        <div v-else-if="index == chunkTotal" :class="{ doneU: checkChunk(chunkCurrent, index, 'green'), doneD: checkChunk(chunkCurrent, index, 'red'), chunkRight: true }">{{ index }}</div>
        <div v-else="index == chunkTotal" :class="{ doneU: checkChunk(chunkCurrent, index, 'green'), doneD: checkChunk(chunkCurrent, index, 'red'), chunk: true }">{{ index }}</div>
      </div>
    </div>
    <p>{{ Math.round((chunkCurrent/chunkTotal)*100) }}%</p>
  </div>
</template>

<style scoped>
  .progress {
    margin-inline: 1em;
    display: flex;
    gap: 1em;
  }

  .bar {
    display: flex;
  }

  .chunk {
    color: var(--mid-color);
  }
  .chunkLeft {
    border-radius: 1em 0 0 1em;
    color: var(--mid-color);
  } 
  .chunkRight {
    border-radius: 0 1em 1em 0;
    color: var(--mid-color);
  }

  .doneU {
    background-color: #23C552 !important;
    color: #23C552 !important;
  }
  .doneD {
    background-color: #CC071E !important;
    color: #CC071E !important;
  }

  .grow {
    flex: 1;
  }
</style>