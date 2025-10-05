window.app = {
  getSources: async () => {
    const cachedSources = localStorage.getItem("sources");
    if (cachedSources) {
      console.log("Loading sources from cache...");
      return JSON.parse(cachedSources);
    }
    const sources = await window.mockData.getSources();
    localStorage.setItem("sources", JSON.stringify(sources));
    return sources;
  },

  getSessions: async (sourceId) => {
    const cachedSessions = localStorage.getItem(`sessions_${sourceId}`);
    if (cachedSessions) {
      console.log(`Loading sessions for ${sourceId} from cache...`);
      return JSON.parse(cachedSessions);
    }
    const sessions = await window.mockData.getSessions(sourceId);
    localStorage.setItem(`sessions_${sourceId}`, JSON.stringify(sessions));
    return sessions;
  },

  renderSources: async () => {
    const sources = await app.getSources();
    const container = document.getElementById("sources-container");
    container.innerHTML = "";
    sources.forEach(source => {
      const sourceElement = document.createElement("a");
      sourceElement.className = "block bg-surface-dark p-4 rounded-lg shadow-lg hover:bg-primary/30 transition-colors duration-200";
      sourceElement.href = `../sessions/code.html?sourceId=${source.id}&sourceName=${encodeURIComponent(source.name)}`;
      sourceElement.innerHTML = `
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <span class="material-symbols-outlined text-accent-green" style="font-size: 32px;">hub</span>
            <div>
              <h3 class="font-bold text-white">${source.name}</h3>
              <p class="text-sm text-gray-400">${source.description}</p>
            </div>
          </div>
          <span class="material-symbols-outlined text-gray-500">chevron_right</span>
        </div>
      `;
      container.appendChild(sourceElement);
    });
  },

  renderSessions: async () => {
    const urlParams = new URLSearchParams(window.location.search);
    const sourceId = urlParams.get("sourceId");
    const sourceName = urlParams.get("sourceName");

    if (sourceName) {
        const titleElement = document.getElementById("source-name-title");
        if(titleElement) titleElement.textContent = sourceName;
    }

    if (!sourceId) return;

    const sessions = await app.getSessions(sourceId);
    const container = document.getElementById("sessions-container");
    container.innerHTML = "";
    sessions.forEach(session => {
      const sessionElement = document.createElement("div");
      sessionElement.className = "flex items-center gap-4 bg-[#181122] px-4 min-h-[72px] py-2";
      sessionElement.innerHTML = `
        <div class="text-white flex items-center justify-center rounded-lg bg-[#332348] shrink-0 size-12" data-icon="Code" data-size="24px" data-weight="regular">
          <svg xmlns="http://www.w3.org/2000/svg" width="24px" height="24px" fill="currentColor" viewBox="0 0 256 256">
            <path d="M69.12,94.15,28.5,128l40.62,33.85a8,8,0,1,1-10.24,12.29l-48-40a8,8,0,0,1,0-12.29l48-40a8,8,0,0,1,10.24,12.3Zm176,27.7-48-40a8,8,0,1,0-10.24,12.3L227.5,128l-40.62,33.85a8,8,0,1,0,10.24,12.29l48-40a8,8,0,0,0,0-12.29ZM162.73,32.48a8,8,0,0,0-10.25,4.79l-64,176a8,8,0,0,0,4.79,10.26A8.14,8.14,0,0,0,96,224a8,8,0,0,0,7.52-5.27l64-176A8,8,0,0,0,162.73,32.48Z"></path>
          </svg>
        </div>
        <div class="flex flex-col justify-center">
          <p class="text-white text-base font-medium leading-normal line-clamp-1">${session.name}</p>
          <p class="text-[#a992c9] text-sm font-normal leading-normal line-clamp-2">${session.date}</p>
        </div>
      `;
      container.appendChild(sessionElement);
    });
  }
};