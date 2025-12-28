<script setup lang="ts">
  import Progress from '../components/progress.vue';
  import { ref, type Ref } from 'vue';

  const emit = defineEmits(['update']);
  const props = defineProps<{
    channelData: any;
    channelId: any;
    loading: boolean;
  }>()

  import { useCookies } from '@vueuse/integrations/useCookies';
  const cookies = useCookies(['token']);
  const token = cookies.get('token');

  const active: Ref<boolean> = ref(false);
  const color: Ref<'green' | 'red'>= ref('red');
  const chunkTotal: Ref<number>= ref(0); 
  const chunkCurrent: Ref<number>= ref(0);

  const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

  const filteredChannelData: any = () => { 
    let filteredChannelData = [];
    let filteredIds: string[] = [];
    for (let i = 0; i < props.channelData.length; i++) {
      const file = props.channelData[i];
      if(!filteredIds.includes(idFileName(file.attachments[0].filename))) {
        filteredIds.push(idFileName(file.attachments[0].filename));
        filteredChannelData.push(file);
      }
    }
    return filteredChannelData;
  }

  function calcSize(message: any): string {
    let size = 0;
    let result = 0;
    let str = '';
    const targetBaseName = idFileName(message.attachments[0].filename);
    const filteredMessages = props.channelData.filter((msg: any) => idFileName(msg.attachments[0].filename) === targetBaseName);
    for (let i = 0; i < filteredMessages.length; i++) {
      size = size + filteredMessages[i].attachments[0].size;
    }
    if(size/1024/1024/1024 >= 1) { result = size/1024/1024/1024; str = 'GB' }
    else if(size/1024/1024 >= 1) { result = size/1024/1024; str = 'MB' }
    else { result = size/1024; str = 'KB' }
    return Math.round(result)+str;
  }

  function cleanFileName(name: string): string {
    const index = name.indexOf('-_-');
    const dotIndex = name.indexOf('.');
    const filetype = dotIndex !== -1 ? name.slice(dotIndex) : "";
    const cleanName = (index !== -1 ? name.slice(0, index) : name)+filetype;
    return cleanName;
  }

  function idFileName(name: string): string {
    const index = name.indexOf('---');
    const dotIndex = name.indexOf('.');
    const filetype = dotIndex !== -1 ? name.slice(dotIndex) : "";
    const idName = (index !== -1 ? name.slice(0, index) : name)+filetype;
    return idName;
  }

  function getChunkNumber(name: string): string {
    const index = name.indexOf('---');
    const id = (index !== -1 ? name.slice(index) : name).split("_");
    return id[0]!.replace(/-/g, '');
  }

  function upload() {
    const maxSize = 10 * 1024 * 1024;
    const rand = Math.floor(100000 + Math.random() * 900000);
    const input = document.createElement('input');
    input.type = 'file';
    input.onchange = async(e) => {
      const file = (e.target! as any).files[0];
      const totalChunks = Math.ceil(file.size / maxSize);
      // Progress bar
      active.value = true;
      color.value =  'green';
      chunkTotal.value =  totalChunks; 
      chunkCurrent.value = 0;
      for(let i = 0; i < totalChunks; i++) {
        const start = i * maxSize;
        const end   = Math.min(start + maxSize, file.size);
        const chunk = file.slice(start, end);
        await uploadFile(chunk, file.name, rand, i, totalChunks)
      }
      emit('update', [false, false, false, true]);
      active.value = false;
    };
    input.click();
  }
  async function uploadFile(file: File, name: string, rand: number, chunkIndex: number, totalChunks: number) {
    const dotIndex = name.indexOf('.');
    const filetype = dotIndex !== -1 ? name.slice(dotIndex) : "";
    const cleanName = dotIndex !== -1 ? name.slice(0, dotIndex) : name;
    const filename = cleanName + '-_-' + rand + '---' + (chunkIndex+1) + '_' + totalChunks + filetype;
    try {
      const postPath = '/api/v10/channels/'+props.channelId+'/messages';
      const formData =  new FormData();
      formData.append('file', file, filename);
      const postReq = await fetch(`https://api.cait.moe/v1/drive/discord?path=${postPath}&token=${token}`, {
        method: 'POST',
        body: formData,
      });
      console.log(`> Upload chunk ${chunkIndex + 1}/${totalChunks} (${postReq.status})`);
      chunkCurrent.value = chunkIndex + 1;
      if (!postReq.ok) throw new Error('Network error postReq');
    }
    catch (err) { console.log(err); } 
  }

  async function deleteF(message: any) { 
    const targetBaseName = idFileName(message.attachments[0].filename);
    const filteredMessages = props.channelData.filter((msg: any) => idFileName(msg.attachments[0].filename) === targetBaseName);
    // Progress bar
    active.value = true;
    color.value =  'red';
    chunkTotal.value =  filteredMessages.length; 
    chunkCurrent.value = 0;
    for (let i = 0; i < filteredMessages.length; i++) {
      await deleteFile(filteredMessages[i].id, filteredMessages[i].channel_id);
      chunkCurrent.value = i+1;
    }
    emit('update', [false, false, false, true]);
    active.value = false;
  }
  async function deleteFile(id: string, channel_id: string) {
    try {
      const limitAttempts = 3;
      const wait = 3;
      let success = false;
      let i = 0;
      while(!success && !(i >= limitAttempts)) {
        const deletePath = '/api/v10/channels/'+channel_id+'/messages/'+id;
        const deleteReq = await fetch(`https://api.cait.moe/v1/drive/discord?path=${deletePath}&token=${token}`, { method: "DELETE" })
        console.log(`DELETE ${deletePath} (${deleteReq.status})`)
        if (!deleteReq.ok) {
          console.log(`Retrying DELETE ${id} after ${wait}s`);
          await sleep(wait*1000);
        } else { success = true; }
      }
      if (!success) throw new Error('Network error deleteReq');
    } catch (err) { console.log(err); } 
  }

  async function downloadFile(message: any) {
    try {
      const targetBaseName = idFileName(message.attachments[0].filename);
      const sortedMessages = props.channelData
        .filter((msg: any) => idFileName(msg.attachments[0].filename) === targetBaseName)
        .sort((a: any, b: any) => {
          return getChunkNumber(a.attachments[0].filename).localeCompare(getChunkNumber(b.attachments[0].filename), undefined, { numeric: true, sensitivity: 'base'});
        });
      const chunks: Blob[] = [];
      // Progress bar
      active.value = true;
      color.value =  'green';
      chunkTotal.value =  sortedMessages.length; 
      chunkCurrent.value = 0;
      for (let i = 0; i < sortedMessages.length; i++) {
        const originalUrl = sortedMessages[i].attachments[0].url;
        const pathOnly = originalUrl.replace("https://cdn.discordapp.com", "");
        const encodedPath = btoa(pathOnly);
        const proxyUrl = `https://api.cait.moe/v1/drive/discord/cdn?path=${encodedPath}`;
        const response = await fetch(proxyUrl);
        console.log(`> Download chunk ${i + 1}/${sortedMessages.length} (${response.status}) ${proxyUrl}`);
        if (!response.ok) throw new Error(`Error fetching chunk ${i}`);
        const blob = await response.blob();
        chunks.push(blob);
        chunkCurrent.value = i+1;
      }
      const finalBlob = new Blob(chunks, { type: chunks[0]!.type });
      
      const downloadUrl = URL.createObjectURL(finalBlob);
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = cleanFileName(message.attachments[0].filename) || 'assembled-file';
      link.click();
      URL.revokeObjectURL(downloadUrl);
      active.value = false;
    } catch (err) { console.error("Download failed:", err); }
  }
</script>

<template>
  <div class="main">
    <div class="grow">
      <div v-if="props.loading === false">
        <div class="messages" v-for="(message) in filteredChannelData()">
          <div v-if="(message.attachments.length > 0)" class="message">
            <p>{{ cleanFileName(message.attachments[0].filename) }} ({{ message.attachments[0].content_type }}) - {{ calcSize(message) }} </p>
            <div class="actions">
              <button @click="downloadFile(message)">
                <svg class="button" width="800px" height="800px" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 15C3 17.8284 3 19.2426 3.87868 20.1213C4.75736 21 6.17157 21 9 21H15C17.8284 21 19.2426 21 20.1213 20.1213C21 19.2426 21 17.8284 21 15" stroke="#1C274C" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M12 3V16M12 16L16 11.625M12 16L8 11.625" stroke="#1C274C" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
              </button>
              <button @click="deleteF(message)">
                <svg class="button" width="800px" height="800px" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10 12V17" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M14 12V17" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 7H20" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 10V18C6 19.6569 7.34315 21 9 21H15C16.6569 21 18 19.6569 18 18V10" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M9 5C9 3.89543 9.89543 3 11 3H13C14.1046 3 15 3.89543 15 5V7H9V5Z" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="add">
      <div class="grow">
        <Progress :active :color :chunkCurrent :chunkTotal />
      </div>
      <button @click="upload()">
        <p>Upload File</p>
      </button>
    </div>
  </div>
</template>

<style scoped>
  .main {
    background-color: var(--mid-color);
    border-radius: 0 0 1em 0;
    max-width: 85%;
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    align-items: stretch;
  }

  .messages {
    overflow-x: auto;
    height: 100%;
  } .messages:nth-child(2n) {
    filter: brightness(1.2);
  }

  .message {
    background-color: var(--mid-color);
    padding: 1em;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .add {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-radius: 0 0 1em 0;
  }
  .add>button {
    width: 10%;
    border-radius: 1em 0 1em 0;
  }

  .actions {
    display: flex;
    gap: 1em;
  }

  .button {
    height: 1vw;
    width: 1vw;
  }

  .grow {
    flex: 1;
    overflow-y: auto;
  }
</style>