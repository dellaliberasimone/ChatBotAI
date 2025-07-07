import axios from 'axios';
import { ChatRequest, ChatResponse } from '../types/chat';

// Get API URL from Aspire environment variable, fallback to process.env, then localhost
const getApiUrl = () => {
  // First check if Aspire provided the backend URL via environment variable
  //const aspireBackendUrl = process.env.REACT_APP_API_URL;

  const aspireBackendUrl = process.env.REACT_APP_API_URL;
  
  // Log the URL being used for debugging
  console.log('API URL being used:', aspireBackendUrl);
  
  return aspireBackendUrl;
};

const API_URL = getApiUrl();

export const chatService = {
  async sendMessage(message: string): Promise<ChatResponse> {
    try {
      const request: ChatRequest = { message };
      const response = await axios.post<ChatResponse>(`${API_URL}/api/chat`, request);
      return response.data;
    } catch (error) {
      console.error('Errore nel mandare il messaggio:', error);
      return {
        text: 'Errore nella esecuzione della richiesta',
        type: 'bot'
      };
    }
  }
};
