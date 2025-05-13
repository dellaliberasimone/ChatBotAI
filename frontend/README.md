# ChatbotAI Frontend

This is the frontend React application for the ChatbotAI project. It provides a user-friendly chat interface that communicates with our backend API powered by Azure OpenAI.

## Features

- Modern chat interface with user and bot messages
- Real-time message sending and receiving
- Visual typing indicators when waiting for responses
- Responsive design that works on both desktop and mobile devices

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Setup and Configuration

Before running the application, make sure to set up your environment:

1. Create a `.env` file in the root directory
2. Set `REACT_APP_API_URL` to your backend API URL (default: http://localhost:5169)

## Integration with Backend

The frontend communicates with the backend API using the following endpoints:
- `POST /api/chat`: Send a message to the chatbot and receive a response

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.\
You will also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Project Structure

- `src/components/`: React components
  - `Chat.tsx`: Main chat container component
  - `MessageComponent.tsx`: Individual message display component
- `src/services/`: API services
  - `chatService.ts`: Service for communicating with backend API
- `src/types/`: TypeScript type definitions
  - `chat.ts`: Types for chat messages and API requests/responses

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).
