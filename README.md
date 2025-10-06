# jules-ios

An iOS application that integrates with the [Jules API](https://developers.google.com/jules/api) to let developers connect GitHub repositories, create sessions, and interact with an AI coding agent directly from their phone.

---

## Overview

`jules-ios` is a native iOS app written in SwiftUI that provides a simple interface for working with Jules.  
The app allows you to:

- Connect your Jules API key (stored securely).
- View connected sources (GitHub repositories).
- Create and manage sessions for each source.
- Interact with an AI agent inside a session by sending prompts and receiving responses.

---

## Design

Screens for the design of this application are in the `screens/` directory. Each scren is a sub directory, and it contains an image of the screen as `screen.png` and HTML/CSS in `code.html`. When building the real screens in the app, look for the corresponding screen directories which are mentioned below.

### Homescreen
- The screen design is in the `screens/homescreen` directory
- Displays a **table view list** of connected sources (GitHub repositories).
- Each row represents a source.
- Tapping on a row navigates to the **Sessions View** for that source.

### Sessions View
- The screen design is in the `screens/sessions` directory
- Displays a list of sessions for the selected source.
- A bottom button **[ CREATE SESSION ]** allows creating a new session.
  - Tapping the button prompts the user for:
    - `title` (e.g., `Boba App`)
    - `prompt` (e.g., `Create a boba app!`)
  - On submission, the app calls the Jules API to create a session.
  - After creation, the list of sessions is refreshed.

### Activities View
- The screen design is in the `screens/activities` directory
- Displays the list of activities for the selected session.
- Each activity represents an interaction with the agent.
- A bottom button **[ TALK TO AGENT ]** allows sending a new prompt.
  - Prompts the user for a message.
  - Makes an API call to send that message to the agent.
  - The immediate response is empty — the agent reply will arrive as a new activity.
  - Refreshing the list shows the agent’s response.

### Settings
- The screen design is in the `screens/settings` directory
- When the app first launches, the user is asked for their Jules API key (which must be generated in the Jules web app Settings).
- The API key is stored securely (Keychain).
- Settings screen allows updating or re-adding an API key.
- After updating the API key, the app refreshes all data.

---

## Implementation

### API Integration
- The Jules API is documented here: [https://developers.google.com/jules/api](https://developers.google.com/jules/api).
- API calls include:
  - Fetching sources
  - Fetching sessions for a source
  - Creating a session
  - Fetching activities for a session
  - Sending a message to the agent

### iOS Architecture
- Built with **SwiftUI** for a modern, declarative UI.
- Use **MVVM** pattern to separate data (API models), state, and UI.
- Networking implemented with `URLSession` and `async/await`.
- Secure API key storage handled via **Keychain**.

NOTE: This is an iOS application. Do NOT do anything with the code.html files, or at any time think there is a web component and make changes there.

### Project Setup
1. Open **Xcode** (latest stable version).
2. Create a new project named `jules-ios`.
3. Select **iOS App** template with Swift and SwiftUI.
4. Add necessary models for `Source`, `Session`, `Activity`.
5. Create API client layer for interacting with Jules API.
6. Build out the SwiftUI views:
   - `HomeView` → lists sources
   - `SessionsView` → lists sessions, create session
   - `ActivitiesView` → lists activities, talk to agent
   - `SettingsView` → manage API key

---

## Next Steps
- Implement Jules API client in Swift.
- Wire up SwiftUI views with data models.
- Add persistence for API key.
- Test flows: add API key → view sources → create session → send activity → refresh activities.

---

## API

The application interacts with the Jules API to fetch data and perform actions. Below are examples of the API calls and responses.

### Sources
This endpoint retrieves a list of the user's connected source code repositories.

See an example API trace: [`api-traces/sources.txt`](api-traces/sources.txt)

### Sessions
This endpoint retrieves a list of active and past sessions.

See an example API trace: [`api-traces/sessions.txt`](api-traces/sessions.txt)

### Activities
This endpoint retrieves the activities for a given session. Activities represent the conversation between the user and the agent.

See an example API trace: [`api-traces/activities.txt`](api-traces/activities.txt)

---

## License
[Apache](LICENSE)