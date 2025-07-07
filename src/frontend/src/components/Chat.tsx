import React, { useState, useEffect, useRef } from 'react';
import styled from 'styled-components';
import { v4 as uuidv4 } from 'uuid';
import { MessageComponent } from './MessageComponent';
import { chatService } from '../services/chatService';
import { ChatMessage } from '../types/chat';
import { FaPaperPlane, FaRobot } from 'react-icons/fa';

const ChatContainer = styled.div`
  display: flex;
  flex-direction: column;
  height: 100%;
  max-width: 800px;
  margin: 0 auto;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
  background-color: white;
`;

const ChatHeader = styled.div`
  background-color: #5c6bc0;
  color: white;
  padding: 16px;
  font-size: 1.25rem;
  font-weight: 500;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
`;

const BotAvatar = styled.div`
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background-color: #727cf5;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
  color: white;
`;

const ChatMessages = styled.div`
  flex: 1;
  padding: 16px;
  overflow-y: auto;
  background-color: #f9f9f9;
  display: flex;
  flex-direction: column;
`;

const ChatInputContainer = styled.form`
  display: flex;
  padding: 16px;
  background-color: white;
  border-top: 1px solid #e0e0e0;
`;

const ChatInput = styled.input`
  flex: 1;
  padding: 12px 16px;
  border: 1px solid #ddd;
  border-radius: 24px;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;

  &:focus {
    border-color: #5c6bc0;
  }
`;

const SendButton = styled.button`
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background-color: #5c6bc0;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  margin-left: 8px;
  cursor: pointer;
  transition: background-color 0.2s;

  &:hover {
    background-color: #3f51b5;
  }

  &:disabled {
    background-color: #b0b0b0;
    cursor: not-allowed;
  }
`;

const WelcomeMessage = styled.div`
  text-align: center;
  padding: 24px;
  color: #666;
  font-size: 1.1rem;
`;

const TypingIndicator = styled.div`
  display: flex;
  padding: 12px 16px;
  align-self: flex-start;

  span {
    height: 8px;
    width: 8px;
    margin: 0 1px;
    background-color: #727cf5;
    border-radius: 50%;
    display: inline-block;
    animation: typing 1s infinite ease-in-out;

    &:nth-child(1) {
      animation-delay: 0s;
    }
    &:nth-child(2) {
      animation-delay: 0.2s;
    }
    &:nth-child(3) {
      animation-delay: 0.4s;
    }
  }

  @keyframes typing {
    0% {
      transform: translateY(0px);
    }
    50% {
      transform: translateY(-10px);
    }
    100% {
      transform: translateY(0px);
    }
  }
`;

export const Chat: React.FC = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Scroll to the bottom when messages change
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (inputValue.trim() === '' || isLoading) return;

    const userMessage: ChatMessage = {
      id: uuidv4(),
      text: inputValue,
      type: 'user',
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await chatService.sendMessage(userMessage.text);
      
      const botMessage: ChatMessage = {
        id: uuidv4(),
        text: response.text,
        type: 'bot',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, botMessage]);
    } catch (error) {
      console.error('Errore nel mandare il messaggio:', error);
      
      const errorMessage: ChatMessage = {
        id: uuidv4(),
        text: 'Mi dispiace, ho incontrato un errore durante la tua richiesta.',
        type: 'bot',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };
  return (
    <ChatContainer>      <ChatHeader>
        <BotAvatar>
          {FaRobot({})}
        </BotAvatar>
        ChatbotAI Assistant
      </ChatHeader>
      <ChatMessages>
        {messages.length === 0 && (
          <WelcomeMessage>
            Welcome! How can I assist you today?
          </WelcomeMessage>
        )}
        
        {messages.map((message) => (
          <MessageComponent key={message.id} message={message} />
        ))}
        
        {isLoading && (
          <TypingIndicator>
            <span></span>
            <span></span>
            <span></span>
          </TypingIndicator>
        )}
        
        <div ref={messagesEndRef} />
      </ChatMessages>
      <ChatInputContainer onSubmit={handleSubmit}>
        <ChatInput
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          placeholder="Scrivi un messaggio..."
          disabled={isLoading}
        />        <SendButton type="submit" disabled={inputValue.trim() === '' || isLoading}>
          {FaPaperPlane({ size: 16 })}
        </SendButton>
      </ChatInputContainer>
    </ChatContainer>
  );
};
