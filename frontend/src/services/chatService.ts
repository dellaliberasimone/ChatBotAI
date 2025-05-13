import axios from 'axios';
import { ChatRequest, ChatResponse } from '../types/chat';

// First check for runtime config from window.ENV, then build-time env vars, then fallback
const API_URL = (window as any).ENV?.API_URL || process.env.REACT_APP_API_URL || 'http://localhost:5000';

export const chatService = {
  async sendMessage(message: string): Promise<ChatResponse> {
    try {
      const request: ChatRequest = { message };
      const response = await axios.post<ChatResponse>(`${API_URL}/api/chat`, request);
      return response.data;
    } catch (error) {
      console.error('Error sending message:', error);
      return {
        text: 'Sorry, there was an error processing your request. Please try again later.',
        type: 'bot'
      };
    }
  }
};
