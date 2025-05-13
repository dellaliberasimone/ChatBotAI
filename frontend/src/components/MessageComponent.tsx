import React from 'react';
import styled from 'styled-components';
import { ChatMessage } from '../types/chat';
import { FaRobot, FaUser } from 'react-icons/fa';

interface ChatMessageProps {
  message: ChatMessage;
}

const MessageContainer = styled.div<{ isUser: boolean }>`
  display: flex;
  margin: 16px 0;
  flex-direction: ${props => props.isUser ? 'row-reverse' : 'row'};
`;

const Avatar = styled.div<{ isUser: boolean }>`
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: ${props => props.isUser ? '#3e6ae1' : '#727cf5'};
  color: white;
  margin: ${props => props.isUser ? '0 0 0 12px' : '0 12px 0 0'};
`;

const MessageBubble = styled.div<{ isUser: boolean }>`
  max-width: 70%;
  padding: 12px 16px;
  border-radius: 18px;
  background-color: ${props => props.isUser ? '#3e6ae1' : '#f1f3f4'};
  color: ${props => props.isUser ? 'white' : '#333'};
  font-size: 1rem;
  line-height: 1.4;
  position: relative;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
`;

const MessageTime = styled.div<{ isUser: boolean }>`
  font-size: 0.7rem;
  color: #999;
  margin-top: 4px;
  text-align: ${props => props.isUser ? 'right' : 'left'};
  padding: 0 8px;
`;

export const MessageComponent: React.FC<ChatMessageProps> = ({ message }) => {
  const isUser = message.type === 'user';
  const time = new Date(message.timestamp).toLocaleTimeString([], { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
  return (
    <div>
      <MessageContainer isUser={isUser}>        <Avatar isUser={isUser}>
          {isUser ? FaUser({}) : FaRobot({})}
        </Avatar>
        <MessageBubble isUser={isUser}>
          {message.text}
        </MessageBubble>
      </MessageContainer>
      <MessageTime isUser={isUser}>{time}</MessageTime>
    </div>
  );
};
