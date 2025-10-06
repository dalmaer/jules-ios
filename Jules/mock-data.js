window.mockData = {
  getSources: async () => {
    console.log("Fetching sources from API...");
    await new Promise(resolve => setTimeout(resolve, 500));
    return [
      { id: "boba-app", name: "Boba-App", description: "A delicious boba ordering application." },
      { id: "jules-ios-client", name: "jules-ios-client", description: "The very app you're using right now." },
      { id: "project-phoenix", name: "Project-Phoenix", description: "Next-gen web framework." },
      { id: "dotfiles", name: "dotfiles", description: "Personal configuration files." },
    ];
  },
  getSessions: async (sourceId) => {
    console.log(`Fetching sessions for ${sourceId} from API...`);
    await new Promise(resolve => setTimeout(resolve, 500));
    const sessions = {
      "boba-app": [
        { id: "1", name: "Boba App", date: "2024-07-24" },
        { id: "2", name: "Mobile App", date: "2024-07-23" },
        { id: "3", name: "Web App", date: "2024-07-22" },
      ],
      "jules-ios-client": [
          { id: "4", name: "iOS Client", date: "2024-07-25" },
      ],
      "project-phoenix": [
        { id: "5", name: "Phoenix Server", date: "2024-07-26" },
      ],
      "dotfiles": [
        { id: "6", name: "My Dotfiles", date: "2024-07-27" },
      ]
    };
    return sessions[sourceId] || [];
  }
};