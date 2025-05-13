import React from 'react';
import styled from 'styled-components';
import { Chat } from './components/Chat';
import './App.css';

const AppContainer = styled.div`
  height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 2rem;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
`;

const Header = styled.header`
  margin-bottom: 2rem;
  text-align: center;
`;

const Title = styled.h1`
  color: #3e4a5b;
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
`;

const Subtitle = styled.h2`
  color: #6c757d;
  font-size: 1.2rem;
  font-weight: 400;
`;

const Main = styled.main`
  flex: 1;
  display: flex;
  flex-direction: column;
`;

const Footer = styled.footer`
  text-align: center;
  padding: 1rem 0;
  color: #6c757d;
  font-size: 0.9rem;
`;

function App() {
  return (
    <AppContainer>
      <Header>
        <Title>ChatbotAI</Title>
        <Subtitle>Your intelligent assistant</Subtitle>
      </Header>
      <Main>
        <Chat />
      </Main>
      <Footer>
        &copy; {new Date().getFullYear()} ChatbotAI - Powered by Azure OpenAI
      </Footer>
    </AppContainer>
  );
}

export default App;
