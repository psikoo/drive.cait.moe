<script setup lang="ts">
  import ProvideToken from './components/provideToken.vue';
  import Header from './layouts/header.vue';
  import Sidebar from './layouts/sidebar.vue';
  import Content from './layouts/content.vue';
  
  import { onMounted, ref, type Ref } from 'vue';
  import { useCookies } from '@vueuse/integrations/useCookies';
  const cookies = useCookies(['token']);
  const token = cookies.get('token');

  const bot: Ref<any> = ref(null);
  const guilds: Ref<any> = ref(null);
  const guildId: Ref<string | null> = ref(null);
  const channels: Ref<any> = ref(null);
  const channelId: Ref<string | null> = ref(null);
  const channelData: Ref<any> = ref([]);
  const loading = ref(true);

  async function changeChannel(channelIdIn: string) {
    const urlParams = new URLSearchParams(window.location.search);
    if(!urlParams.has("channelId")) {
      urlParams.set("channelId", channelIdIn);
      window.history.pushState({}, "", "?"+urlParams.toString());
    } 
    else if(urlParams.get("channelId") != channelIdIn) {
      urlParams.set("channelId", channelIdIn);
      window.history.pushState({}, "", "?"+urlParams.toString());
    } 
    channelId.value = channelIdIn;
    fetchData([false, false, false, true]);
  }

  async function fetchData(update: boolean[]) {
    try {
      if(update[0]) {
        const botPath = '/api/v10/users/@me';
        console.log(`GET ${botPath}`)
        const botReq = await fetch(`https://api.cait.moe/v1/drive/discord?path=${botPath}&token=${token}`, {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' }
        });
        if (!botReq.ok) throw new Error('Network error botReq');
        bot.value = await botReq.json();
      }
      if(update[1]) {
        const guildsPath = '/api/v10/users/@me/guilds';
        console.log(`GET ${guildsPath}`)
        const guildsReq = await fetch(`https://api.cait.moe/v1/drive/discord?path=${guildsPath}&token=${token}`, {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' }
        });
        if (!guildsReq.ok) throw new Error('Network error guildsReq');
        guilds.value = await guildsReq.json();
        guildId.value = await guilds.value[0].id;
      }
      if(update[2]) {
        const channelsPath = '/api/v10/guilds/'+guildId.value+'/channels';
        console.log(`GET ${channelsPath}`)
        const channelsReq = await fetch(`https://api.cait.moe/v1/drive/discord?path=${channelsPath}&token=${token}`, {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' }
        });
        if (!channelsReq.ok) throw new Error('Network error channelsReq');
        channels.value = await channelsReq.json();
        channelId.value = await channels.value[0].id;
      }
      if(update[3]) {
        channelData.value = [];
        const channelDataPath = '/api/v10/channels/'+channelId.value+'/messages';
        let lastId = null;
        let fetching = true;
        while(fetching) {
          let channelDataUrl = `https://api.cait.moe/v1/drive/discord?path=${channelDataPath}&token=${token}&limit=100`
          if(lastId) channelDataUrl += `&before=${lastId}`;
          console.log(`GET ${channelDataUrl} ${lastId? lastId : 'unknown'}`)
          const channelDataReq = await fetch(channelDataUrl, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
          });
          if (!channelDataReq.ok) throw new Error('Network error channelDataReq');
          const res = await channelDataReq.json()
          channelData.value.push(...res);
          if(res.length < 100) fetching = false;
          else lastId = res[res.length - 1].id;
        }
      }
    } 
    catch (err) { console.log(err); } 
    finally { loading.value = false; }
  };
  onMounted(() => {
    fetchData([true, true, true, true]);
  })
</script>

<template>
  <main v-if="token != null">
    <div class="header">
      <Header :bot :guilds :loading></Header>
    </div>
    <div class="content">
      <Sidebar :channels :channelId :loading 
        @changeChannel="(channelId: string) => changeChannel(channelId)"
        @update="(update: boolean[]) => fetchData(update)"
      />
      <Content :channelData :channelId :loading
        @update="(update: boolean[]) => fetchData(update)"
      />
    </div>
  </main>
  <main v-else>
    <ProvideToken></ProvideToken>
  </main>
</template>

<style scoped>
  main {
    margin: 1vh;
  }

  .header {
    height: 5vh;
    padding: 1vh;
    display: flex;
    gap: 1vh;
    align-items: center;
    border-radius: 1em 1em 0 0;
    background-color: var(--light-color);
    border-bottom: 1px solid var(--border-color);
  }

  .content {
    display: flex;
    height: 90vh;
  }
</style>